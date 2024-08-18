local Packet = require("packets/Packet.mod")
local SerDe = require("SerDe.mod")

local GoodbyePacket = require("packets/GoodbyePacket.mod")
local PingPacket = require("packets/PingPacket.mod")

--- @class
--- @extends Node
--- @permissions INTERNAL
local NetworkManager = {}
local NetworkManagerC = gdclass(NetworkManager)

type PacketHandler = {
    [string]: (nm: NetworkManager, peer: number, packet: Packet.Packet) -> (),
}

type PacketHandlerServer = {
    OnServerStart: ((nm: NetworkManager) -> ())?,
    OnPeerConnected: ((nm: NetworkManager, peer: number) -> ())?,
    OnPeerDisconnected: ((nm: NetworkManager, peer: number) -> ())?,
    OnServerClose: ((nm: NetworkManager) -> ())?,

    [string]: (nm: NetworkManager, peer: number, packet: Packet.Packet) -> (),
}

type PacketHandlerClient = {
    OnConnectedToServer: ((nm: NetworkManager) -> ())?,
    OnConnectionFailed: ((nm: NetworkManager) -> ())?,
    OnServerDisconnected: ((nm: NetworkManager) -> ())?,

    [string]: (nm: NetworkManager, packet: Packet.Packet) -> (),
}

export type PeerData = {
    state: number,
    identity: string,
    successfulPings: number,
    rtt: number,
}

export type NetworkManager = Node & typeof(NetworkManager) & {
    multiplayer: SceneMultiplayer,

    --- @signal
    statusUpdate: SignalWithArgs<(details: string, failure: boolean) -> ()>,

    packetHandlerCommon: PacketHandler,
    packetHandlerServer: PacketHandlerServer,
    packetHandlerClient: PacketHandlerClient,

    -- Common state

    -- If generation increases then the connection has reset since the last time checked
    -- (use for timeouts)
    generation: number,

    isActive: boolean,
    isServer: boolean,
    isQuitting: boolean,

    password: string,

    nextPing: number,

    peer: ENetMultiplayerPeer,
    peerData: {[number]: PeerData},

    ser: SerDe.Serializer,

    -- Server state

    mapId: string,

    -- Client state

    host: string,
    port: number,
    identity: string,
}

NetworkManager.PeerState = {
    CONNECTED = 0,
    AUTH = 1,

    JOINED = 10,
    SYNCED = 11,
}

function NetworkManager.Log(self: NetworkManager, ...: any)
    local prefix = "[network] "
    prefix ..= if self.isServer then "[S] " else "[C] "

    print(prefix, ...)
end

function NetworkManager.resetState(self: NetworkManager)
    self.isActive = false
    self.isServer = true

    self.password = ""

    self.nextPing = 0

    self.mapId = ""

    self.host = ""
    self.port = 0
    self.identity = ""
end

--- @registerMethod
function NetworkManager._Ready(self: NetworkManager)
    assert(self.multiplayer:IsA(SceneMultiplayer))

    self.packetHandlerCommon = require("PacketHandlerCommon.mod") :: any
    self.packetHandlerServer = require("PacketHandlerServer.mod") :: any
    self.packetHandlerClient = require("PacketHandlerClient.mod") :: any

    self:GetTree().autoAcceptQuit = false

    self.generation = 0

    self:resetState()

    self.peer = ENetMultiplayerPeer.new()
    self.peerData = {}

    self.ser = SerDe.Serializer.new()

    self.isQuitting = false

    self.multiplayer.connectedToServer:Connect(Callable.new(self, "_OnConnectedToServer"))
    self.multiplayer.serverDisconnected:Connect(Callable.new(self, "_OnServerDisconnected"))

    self.multiplayer.peerConnected:Connect(Callable.new(self, "_OnPeerConnected"))
    self.multiplayer.peerDisconnected:Connect(Callable.new(self, "_OnPeerDisconnected"))

    self.multiplayer.peerPacket:Connect(Callable.new(self, "_OnPeerPacket"))
end

--- @registerMethod
function NetworkManager._Notification(self: NetworkManager, what: number)
    if what == Node.NOTIFICATION_WM_CLOSE_REQUEST then
        if self.peer:GetConnectionStatus() ~= MultiplayerPeer.ConnectionStatus.CONNECTED then
            self:GetTree():Quit()
            return
        end

        self:Log("window close requested. disconnecting...")

        self.isQuitting = true

        if self.isServer then
            self:CloseServer()
        else
            self:DisconnectWithReason(1, "Disconnected")
        end
    end
end

function NetworkManager.sendStatusUpdate(self: NetworkManager, details: string, failure: boolean?, shouldWait: boolean?)
    self.statusUpdate:Emit(details, failure or false)

    if shouldWait == false then
        return
    end

    for i = 1, 2 do
        wait_signal(self:GetTree().processFrame)
    end
end

--#region CONNECTIVITY
----------------------

function NetworkManager.SendPacket(self: NetworkManager, peer: number, packet: Packet.Packet)
    if self.peer:GetConnectionStatus() ~= MultiplayerPeer.ConnectionStatus.CONNECTED or
            (peer > 0 and not self.multiplayer:GetPeers():Has(peer)) then
        return
    end

    self.ser:Seek(0)
    self.ser:SerDe(assert(Packet.Id[packet.NAME]), SerDe.NumberType.U8)
    packet:SerDe(self.ser)

    self.multiplayer:SendBytes(self.ser:Write(), peer,
        packet.MODE or MultiplayerPeer.TransferMode.RELIABLE,
        packet.CHANNEL or 0
    )
end

function NetworkManager.Join(self: NetworkManager, addr: string, port: number, identity: string, password: string?)
    assert(self.peer:GetConnectionStatus() == MultiplayerPeer.ConnectionStatus.DISCONNECTED)

    self.isServer = false

    self:sendStatusUpdate("Connecting...")

    self:Log(`joining server at {addr}:{port}`)

    self.password = password or ""

    self.host = addr
    self.port = port
    self.identity = identity

    local err = self.peer:CreateClient(addr, port)
    if err ~= Enum.Error.OK then
        return err
    end

    self.multiplayer.multiplayerPeer = self.peer
    self.isActive = true

    return Enum.Error.OK
end

function NetworkManager.DisconnectTimeout(self: NetworkManager, peer: number?, pred: (() -> boolean)?)
    local DEFAULT_TIMEOUT = 10
    local generation = self.generation

    coroutine.wrap(function()
        wait(DEFAULT_TIMEOUT)

        if not pred or not pred() or self.generation ~= generation then
            return
        end

        if self.isServer then
            assert(peer)

            if not self.peerData[peer] then
                return
            end

            self:Log(`disconnecting peer {peer} after timeout`)
            self.multiplayer:DisconnectPeer(peer)
        else
            self:Log(`disconnecting after timeout`)
            self:Reset()

            self:sendStatusUpdate("Timed out", true, false)
        end
    end)()
end

function NetworkManager.DisconnectWithReason(self: NetworkManager, peer: number, reason: string, doTimeout: boolean?)
    local packet = GoodbyePacket.server.new(reason)
    self:SendPacket(peer, packet)

    if doTimeout ~= false then
        self:DisconnectTimeout(peer)
    end

    if not self.isServer then
        self:sendStatusUpdate(`Disconnected: {reason}`, true, false)
    end
end

function NetworkManager.Serve(self: NetworkManager, mapId: string, port: number, maxClients: number, password: string?)
    assert(self.peer:GetConnectionStatus() == MultiplayerPeer.ConnectionStatus.DISCONNECTED)
    self:Log(`opening server on map {mapId}: port {port}, max clients {maxClients}`)

    self.password = password or ""

    self.mapId = mapId

    self:sendStatusUpdate("Starting server...")

    local err = self.peer:CreateServer(port, maxClients)
    if err ~= Enum.Error.OK then
        return err
    end

    self.multiplayer.multiplayerPeer = self.peer
    self.isActive = true

    if self.packetHandlerServer.OnServerStart then
        self.packetHandlerServer.OnServerStart(self)
    end

    return Enum.Error.OK
end

function NetworkManager.CloseServer(self: NetworkManager)
    assert(self.peer:GetConnectionStatus() == MultiplayerPeer.ConnectionStatus.CONNECTED and self.isServer)
    self:Log("closing server")

    self:DisconnectWithReason(0, "Server closed", false)

    -- Wait for client to acknowledge packet by leaving, or quit after a bit
    local MAX_WAIT = 5
    local ATTEMPTS = 100
    local timeWaited = 0

    while timeWaited < MAX_WAIT do
        if self.multiplayer:GetPeers():Size() == 0 then
            break
        end

        timeWaited += wait(MAX_WAIT / ATTEMPTS)
    end

    if self.packetHandlerServer.OnServerClose then
        self.packetHandlerServer.OnServerClose(self)
    end

    self:Reset()
end

function NetworkManager.Reset(self: NetworkManager)
    self.peer:Close()
    self.multiplayer.multiplayerPeer = nil

    if self.isQuitting then
        self:Log("quitting...")
        self:GetTree():Quit()
        return
    end

    self:resetState()
    table.clear(self.peerData)

    self.generation += 1
end

function NetworkManager.Ping(self: NetworkManager, peer: number)
    local ping = PingPacket.server.new(false, Time.singleton:GetTicksUsec())
    self:SendPacket(peer, ping)

    local existingPings = self.peerData[peer].successfulPings
    self:DisconnectTimeout(peer, function()
        return self.peerData[peer] and self.peerData[peer].successfulPings == existingPings
    end)
end

--- @registerMethod
function NetworkManager._Process(self: NetworkManager, delta: number)
    if not self.isActive then
        return
    end

    if self.nextPing == 0 then
        if self.isServer then
            for peer, data in self.peerData do
                if data.state < NetworkManager.PeerState.JOINED then
                    continue
                end

                self:Ping(peer)
            end
        elseif self.peerData[1] and self.peerData[1].state >= NetworkManager.PeerState.JOINED then
            self:Ping(1)
        end

        self.nextPing = 1
    else
        self.nextPing = math.max(0, self.nextPing - delta)
    end
end

--#endregion

--#region SIGNALS
-----------------

--- @registerMethod
function NetworkManager._OnConnectedToServer(self: NetworkManager)
    self:Log("client connected")

    if self.packetHandlerClient.OnConnectedToServer then
        self.packetHandlerClient.OnConnectedToServer(self)
    end
end

--- @registerMethod
function NetworkManager._OnConnectionFailed(self: NetworkManager)
    self:Log(`client connection to {self.host}:{self.port} failed`)

    if self.packetHandlerClient.OnConnectionFailed then
        self.packetHandlerClient.OnConnectionFailed(self)
    end
end

--- @registerMethod
function NetworkManager._OnServerDisconnected(self: NetworkManager)
    self:Log("client disconnected")

    if self.packetHandlerClient.OnServerDisconnected then
        self.packetHandlerClient.OnServerDisconnected(self)
    end

    self:Reset()
end

--- @registerMethod
function NetworkManager._OnPeerConnected(self: NetworkManager, peer: number)
    if not self.isServer then
        return
    end

    local enetPeer = assert(self.peer:GetPeer(peer))
    self:Log(`peer connected: {peer} @ {enetPeer:GetRemoteAddress()}:{enetPeer:GetRemotePort()}`)

    if self.packetHandlerServer.OnPeerConnected then
        self.packetHandlerServer.OnPeerConnected(self, peer)
    end
end

--- @registerMethod
function NetworkManager._OnPeerDisconnected(self: NetworkManager, peer: number)
    if not self.isServer then
        return
    end

    self:Log("peer disconnected: ", peer)

    if self.packetHandlerServer.OnPeerDisconnected then
        self.packetHandlerServer.OnPeerDisconnected(self, peer)
    end
end

--- @registerMethod
function NetworkManager._OnPeerPacket(self: NetworkManager, peer: number, buffer: PackedByteArray)
    local de = SerDe.Deserializer.new(buffer)

    local packetId = de:SerDe(0, SerDe.NumberType.U8)
    local packetType = Packet.PacketTypes[packetId]

    if not packetType then
        self:Log("unexpected packet id: ", packetId)
        return
    end

    if self.isServer then
        if not packetType.client then
            self:Log("unexpected packet idfrom client: ", packetId)
            return
        end

        local packet = packetType.client.new() :: Packet.Packet
        packet:SerDe(de)

        self:HandlePacketCommon(peer, packet)
        self:HandlePacketServer(peer, packet)
    else
        if not packetType.server then
            self:Log("unexpected packet id from server: ", packetId)
            return
        end

        local packet = packetType.server.new() :: Packet.Packet
        packet:SerDe(de)

        self:HandlePacketCommon(peer, packet)
        self:HandlePacketClient(packet)
    end

    if not de:AtEnd() then
        self:Log("buffer is larger than expected: ", packetId, " ", buffer)
    end
end

--#endregion

--#region PACKET HANDLING
-------------------------

function NetworkManager.HandlePacketCommon(self: NetworkManager, peer: number, packet: Packet.Packet)
    local handler = self.packetHandlerCommon[packet.NAME]
    if handler then
        handler(self, peer, packet)
    end
end

function NetworkManager.HandlePacketServer(self: NetworkManager, peer: number, packet: Packet.Packet)
    local handler = self.packetHandlerServer[packet.NAME]
    if handler then
        handler(self, peer, packet)
    end
end

function NetworkManager.HandlePacketClient(self: NetworkManager, packet: Packet.Packet)
    local handler = self.packetHandlerClient[packet.NAME]
    if handler then
        handler(self, packet)
    end
end

--#endregion

return NetworkManagerC
