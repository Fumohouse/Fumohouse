local NetworkManager = require("NetworkManager")
local Packet = require("packets/Packet.mod")

local HelloPacket = require("packets/HelloPacket.mod")
local AuthPacket = require("packets/AuthPacket.mod")
local SyncPacket = require("packets/SyncPacket.mod")
local CharacterRequestPacket = require("packets/runtime/CharacterRequestPacket.mod")
local PeerStatusPacket = require("packets/PeerStatusPacket.mod")
local CharacterStatePacket = require("packets/runtime/CharacterStatePacket.mod")

local Utils = require("../utils/Utils.mod")

local MapManagerM = require("../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local PacketHandlerServer = {}

function PacketHandlerServer.OnServerStart(nm: NetworkManager.NetworkManager)
    -- Sad way of avoiding an extremely inconvenient cyclic dependency from NetworkManager thru Character
    MapManager:Load(nm.mapId)
end

function PacketHandlerServer.OnPeerConnected(nm: NetworkManager.NetworkManager, peer: number)
    assert(not nm.peerData[peer])

    nm.peerData[peer] = {
        state = NetworkManager.PeerState.CONNECTED,
        identity = "",
        successfulPings = 0,
        rtt = 0,
    }

    nm:DisconnectTimeout(peer, function()
        return nm.peerData[peer] and nm.peerData[peer].state == NetworkManager.PeerState.CONNECTED
    end)
end

function PacketHandlerServer.OnPeerDisconnected(nm: NetworkManager.NetworkManager, peer: number)
    local status = PeerStatusPacket.server.new(PeerStatusPacket.PeerStatus.LEFT, nm.peerData[peer].identity, peer)
    nm:SendPacket(0, status)

    assert(MapManager.currentRuntime).players:DeleteCharacter(peer)
    nm.peerData[peer] = nil
end

PacketHandlerServer[HelloPacket.client.NAME] = function(nm: NetworkManager.NetworkManager, peer: number, packet: Packet.Packet)
    -- HANDSHAKE: 2) Server HELLO
    local peerData = nm.peerData[peer]

    if peerData.state ~= NetworkManager.PeerState.CONNECTED then
        nm:DisconnectWithReason(peer, "Incorrect stage for handshake begin")
    end

    local hp = packet :: HelloPacket.HelloPacketClient

    if hp.version ~= Utils.version then
        nm:DisconnectWithReason(peer, `Fumohouse version mismatch — server: {Utils.version}, you: {hp.version}`)
        return
    end

    peerData.identity = hp.identity

    local authType = 0

    if nm.password ~= "" then
        authType = bit32.bor(authType, AuthPacket.AuthType.PASSWORD)
    end

    local currentMap = assert(MapManager.currentMap)
    local hello = HelloPacket.server.new(authType, currentMap.manifest.id, currentMap.manifest.version, currentMap.hash)
    nm:SendPacket(peer, hello)

    peerData.state = NetworkManager.PeerState.AUTH
    nm:DisconnectTimeout(peer, function()
        return peerData.state == NetworkManager.PeerState.AUTH
    end)
end

PacketHandlerServer[AuthPacket.client.NAME] = function(nm: NetworkManager.NetworkManager, peer: number, packet: Packet.Packet)
    -- HANDSHAKE: 4) Server JOIN
    local peerData = nm.peerData[peer]

    if peerData.state ~= NetworkManager.PeerState.AUTH then
        nm:DisconnectWithReason(peer, "Incorrect stage for authentication")
    end

    local ap = packet :: AuthPacket.AuthPacket

    if nm.password ~= "" then
        if ap.password ~= nm.password then
            nm:DisconnectWithReason(peer, "Incorrect password")
            return
        end
    end

    local status = PeerStatusPacket.server.new(PeerStatusPacket.PeerStatus.JOIN, peerData.identity, peer)
    nm:SendPacket(0, status)
    peerData.state = NetworkManager.PeerState.JOINED

    nm:Log(`peer {peer} joined as {peerData.identity}`)

    -- Sync state with client
    local syn = SyncPacket.server.new()

    for remotePeer, data in nm.peerData do
        if data.state < NetworkManager.PeerState.JOINED or peer == remotePeer then
            continue
        end

        syn.peers[#syn.peers + 1] = remotePeer
        syn.identities[#syn.identities + 1] = data.identity
    end

    syn.playerCount = #syn.peers
    nm:SendPacket(peer, syn)

    assert(MapManager.currentRuntime).players:SendSyncPacket(peer)
end

PacketHandlerServer[CharacterRequestPacket.client.NAME] = function(nm: NetworkManager.NetworkManager, peer: number, packet: Packet.Packet)
    if nm.peerData[peer].state < NetworkManager.PeerState.JOINED then
        return
    end

    local req = packet :: CharacterRequestPacket.CharacterRequestPacket
    local characterManager = assert(MapManager.currentRuntime).players

    if req.type == CharacterStatePacket.CharacterStateUpdateType.SPAWN then
        characterManager:SpawnCharacter(req.appearance, peer)
    elseif req.type == CharacterStatePacket.CharacterStateUpdateType.APPEARANCE then
        local character = characterManager:GetCharacter(peer)
        if not character then
            return
        end

        local state = CharacterStatePacket.server.new(CharacterStatePacket.CharacterStateUpdateType.APPEARANCE, peer)
        state.appearance = req.appearance

        nm:SendPacket(0, state)
    elseif req.type == CharacterStatePacket.CharacterStateUpdateType.MOVEMENT then
        characterManager:ProcessMovementRequest(peer, req)
    elseif req.type == CharacterStatePacket.CharacterStateUpdateType.DELETE then
        characterManager:DeleteCharacter(peer, req.died)
    end
end

return PacketHandlerServer
