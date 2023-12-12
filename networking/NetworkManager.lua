local Packet = require("packets/Packet.mod")
local SerDe = require("SerDe.mod")

local Utils = require("../utils/Utils.mod")

local HelloPacket = require("packets/HelloPacket.mod")
local GoodbyePacket = require("packets/GoodbyePacket.mod")
local AuthPacket = require("packets/AuthPacket.mod")
local PeerStatusPacket = require("packets/PeerStatusPacket.mod")

local MapManagerM = require("../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local DEFAULT_TIMEOUT = 10

--- @class
--- @extends Node
--- @permissions INTERNAL
local NetworkManager = {}
local NetworkManagerC = gdclass(NetworkManager)

--- @classType NetworkManager
export type NetworkManager = Node & typeof(NetworkManager) & {
    multiplayer: SceneMultiplayer,

    -- Common state

    -- If generation increases then the connection has reset since the last time checked
    -- (use for timeouts)
    generation: number,

    isServer: boolean,
    isQuitting: boolean,

    password: string,

    peer: ENetMultiplayerPeer,
    peerStates: {[number]: number},
    peerIdentities: {[number]: string},

    ser: SerDe.Serializer,

    -- Client state

    host: string,
    port: number,
    identity: string,
}

NetworkManager.PeerState = {
    CONNECTED = 0,
    AUTH = 1,

    JOINED = 10,
    PING = 11,
}

function NetworkManager.Log(self: NetworkManager, ...: any)
    print("[network] ", ...)
end

function NetworkManager.resetState(self: NetworkManager)
    self.isServer = true

    self.password = ""

    self.host = ""
    self.port = 0
    self.identity = ""
end

--- @registerMethod
function NetworkManager._Ready(self: NetworkManager)
    assert(self.multiplayer:IsA(SceneMultiplayer))

    self:GetTree().autoAcceptQuit = false

    self.generation = 0

    self:resetState()

    self.peer = ENetMultiplayerPeer.new()
    self.peerStates = {}
    self.peerIdentities = {}

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

--#region CONNECTIVITY
----------------------

function NetworkManager.SendPacket(self: NetworkManager, peer: number, packet: Packet.Packet)
    if (peer > 0 and not self.peerStates[peer]) or self.peer:GetConnectionStatus() ~= MultiplayerPeer.ConnectionStatus.CONNECTED then
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
    self:Log(`joining server at {addr}:{port}`)

    self.isServer = false

    self.password = password or ""

    self.host = addr
    self.port = port
    self.identity = identity

    local err = self.peer:CreateClient(addr, port)
    if err ~= Enum.Error.OK then
        return err
    end

    self.multiplayer.multiplayerPeer = self.peer

    return Enum.Error.OK
end

function NetworkManager.DisconnectTimeout(self: NetworkManager, peer: number?, pred: (() -> boolean)?, timeout: number?)
    local generation = self.generation

    coroutine.wrap(function()
        wait(timeout or DEFAULT_TIMEOUT)

        if not pred or not pred() or self.generation ~= generation then
            return
        end

        self:Log(`disconnecting peer {peer} after timeout`)

        if self.isServer then
            self.multiplayer:DisconnectPeer(assert(peer))
        else
            self:Reset()
        end
    end)()
end

function NetworkManager.DisconnectWithReason(self: NetworkManager, peer: number, reason: string, doTimeout: boolean?)
    local packet = GoodbyePacket.server.new(reason)
    self:SendPacket(peer, packet)

    if doTimeout ~= false then
        self:DisconnectTimeout(peer)
    end
end

function NetworkManager.Serve(self: NetworkManager, mapId: string, port: number, maxClients: number, password: string?)
    assert(self.peer:GetConnectionStatus() == MultiplayerPeer.ConnectionStatus.DISCONNECTED)
    self:Log(`opening server on map {mapId}: port {port}, max clients {maxClients}`)

    self.password = password or ""

    local err = self.peer:CreateServer(port, maxClients)
    if err ~= Enum.Error.OK then
        return err
    end

    self.multiplayer.multiplayerPeer = self.peer

    MapManager:Load(mapId)

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

    table.clear(self.peerStates)
    table.clear(self.peerIdentities)

    self.generation += 1
end

--#endregion

--#region SIGNALS
-----------------

--- @registerMethod
function NetworkManager._OnConnectedToServer(self: NetworkManager)
    self:Log("client connected")

    self.peerStates[1] = NetworkManager.PeerState.CONNECTED

    local hello = HelloPacket.client.new(Utils.version, self.identity)
    self:SendPacket(1, hello)

    self:DisconnectTimeout(nil, function()
        return self.peerStates[1] == NetworkManager.PeerState.CONNECTED
    end)
end

--- @registerMethod
function NetworkManager._OnConnectionFailed(self: NetworkManager)
    self:Log(`client connection to {self.host}:{self.port} failed`)
end

--- @registerMethod
function NetworkManager._OnServerDisconnected(self: NetworkManager)
    self:Log("client disconnected")
    self:Reset()
end

--- @registerMethod
function NetworkManager._OnPeerConnected(self: NetworkManager, peer: number)
    if not self.isServer then
        return
    end

    local enetPeer = assert(self.peer:GetPeer(peer))
    self:Log(`peer connected: {peer} @ {enetPeer:GetRemoteAddress()}:{enetPeer:GetRemotePort()}`)

    assert(not self.peerStates[peer])

    self.peerStates[peer] = NetworkManager.PeerState.CONNECTED
    self:DisconnectTimeout(peer, function()
        return self.peerStates[peer] == NetworkManager.PeerState.CONNECTED
    end)
end

--- @registerMethod
function NetworkManager._OnPeerDisconnected(self: NetworkManager, peer: number)
    if not self.isServer then
        return
    end

    self:Log("peer disconnected: ", peer)

    local status = PeerStatusPacket.server.new(PeerStatusPacket.PeerStatus.LEFT, self.peerIdentities[peer], peer)
    self:SendPacket(0, status)

    self.peerStates[peer] = nil
    self.peerIdentities[peer] = nil
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
    if packet.NAME == GoodbyePacket.client.NAME then
        local gp = packet :: GoodbyePacket.GoodbyePacket
        self:Log("peer ", peer, " disconnected: ", gp.reason)

        if self.isServer then
            self.multiplayer:DisconnectPeer(peer)
        else
            self:Reset()
        end
    end
end

function NetworkManager.HandlePacketServer(self: NetworkManager, peer: number, packet: Packet.Packet)
    self:Log("packet from client ", peer, ": ", packet.NAME, " ", packet)

    if packet.NAME == HelloPacket.client.NAME then
        local hp = packet :: HelloPacket.HelloPacketClient

        if hp.version ~= Utils.version then
            self:DisconnectWithReason(peer, `Fumohouse version mismatch — server: {Utils.version}, you: {hp.version}`)
            return
        end

        self.peerIdentities[peer] = hp.identity

        local authType = 0

        if self.password ~= "" then
            authType = bit32.bor(authType, AuthPacket.AuthType.PASSWORD)
        end

        local currentMap = assert(MapManager.currentMap)
        local hello = HelloPacket.server.new(authType, currentMap.manifest.id, currentMap.manifest.version, currentMap.hash)
        self:SendPacket(peer, hello)

        self.peerStates[peer] = NetworkManager.PeerState.AUTH
        self:DisconnectTimeout(peer, function()
            return self.peerStates[peer] == NetworkManager.PeerState.AUTH
        end)
    elseif packet.NAME == AuthPacket.client.NAME then
        local ap = packet :: AuthPacket.AuthPacket

        if self.password ~= "" then
            if ap.password ~= self.password then
                self:DisconnectWithReason(peer, "Incorrect password")
                return
            end
        end

        local status = PeerStatusPacket.server.new(PeerStatusPacket.PeerStatus.JOIN, self.peerIdentities[peer], peer)
        self:SendPacket(0, status)
        self.peerStates[peer] = NetworkManager.PeerState.JOINED

        self:Log(`peer {peer} joined as {self.peerIdentities[peer]}`)
    end
end

function NetworkManager.HandlePacketClient(self: NetworkManager, packet: Packet.Packet)
    self:Log("packet from server: ", packet.NAME, " ", packet)

    if packet.NAME == HelloPacket.server.NAME then
        local hp = packet :: HelloPacket.HelloPacketServer

        local map = MapManager.maps[hp.mapId]

        if not map then
            self:DisconnectWithReason(1, "Client doesn't have requested map")
            return
        end

        if map.manifest.version ~= hp.mapVersion then
            self:DisconnectWithReason(1, "Client map version mismatch")
            return
        end

        if map.hash ~= hp.mapHash then
            self:DisconnectWithReason(1, "Client map hash mismatch")
            return
        end

        MapManager:Load(hp.mapId)

        local auth = AuthPacket.client.new()

        if bit32.band(hp.authType, AuthPacket.AuthType.PASSWORD) ~= 0 then
            auth.password = self.password
        end

        self:SendPacket(1, auth)

        self.peerStates[1] = NetworkManager.PeerState.AUTH
        self:DisconnectTimeout(1, function()
            return self.peerStates[1] == NetworkManager.PeerState.AUTH
        end)
    elseif packet.NAME == PeerStatusPacket.server.NAME then
        local psp = packet :: PeerStatusPacket.PeerStatusPacket

        if psp.status == PeerStatusPacket.PeerStatus.JOIN then
            if psp.peer == self.peer:GetUniqueId() then
                self.peerStates[1] = NetworkManager.PeerState.JOINED
                self:Log(`successfully joined as {psp.identity}`)
            else
                self:Log(`peer {psp.peer} joined as {psp.identity}`)
                self.peerIdentities[psp.peer] = psp.identity
            end
        else
            if psp.peer == self.peer:GetUniqueId() then
                return
            end

            self:Log(`peer {psp.peer} ({psp.identity}) left`)
            self.peerIdentities[psp.peer] = nil
        end
    end
end

--#endregion

return NetworkManagerC
