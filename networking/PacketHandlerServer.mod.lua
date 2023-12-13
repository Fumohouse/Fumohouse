local NetworkManager = require("NetworkManager")
local Packet = require("packets/Packet.mod")

local HelloPacket = require("packets/HelloPacket.mod")
local AuthPacket = require("packets/AuthPacket.mod")
local PeerStatusPacket = require("packets/PeerStatusPacket.mod")

local Utils = require("../utils/Utils.mod")

local MapManagerM = require("../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local PacketHandlerServer = {}

function PacketHandlerServer.OnPeerConnected(nm: NetworkManager.NetworkManager, peer: number)
    assert(not nm.peerData[peer])

    nm.peerData[peer] = {
        state = NetworkManager.PeerState.CONNECTED,
        identity = "",
        successfulPings = 0,
        rtt = 0,
    }

    nm:DisconnectTimeout(peer, function()
        return nm.peerData[peer].state == NetworkManager.PeerState.CONNECTED
    end)
end

function PacketHandlerServer.OnPeerDisconnected(nm: NetworkManager.NetworkManager, peer: number)
    local status = PeerStatusPacket.server.new(PeerStatusPacket.PeerStatus.LEFT, nm.peerData[peer].identity, peer)
    nm:SendPacket(0, status)

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
end

return PacketHandlerServer
