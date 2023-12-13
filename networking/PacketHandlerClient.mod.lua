local NetworkManager = require("NetworkManager")
local Packet = require("packets/Packet.mod")

local HelloPacket = require("packets/HelloPacket.mod")
local PeerStatusPacket = require("packets/PeerStatusPacket.mod")
local AuthPacket = require("packets/AuthPacket.mod")

local Utils = require("../utils/Utils.mod")

local MapManagerM = require("../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local PacketHandlerClient = {}

function PacketHandlerClient.OnConnectedToServer(nm: NetworkManager.NetworkManager)
    -- HANDSHAKE: 1) Client HELLO
    nm.peerData[1] = {
        state = NetworkManager.PeerState.CONNECTED,
        identity = "SERVER",
        successfulPings = 0,
        rtt = 0,
    }

    nm.peerData[1].state = NetworkManager.PeerState.CONNECTED

    local hello = HelloPacket.client.new(Utils.version, nm.identity)
    nm:SendPacket(1, hello)

    nm:DisconnectTimeout(nil, function()
        return nm.peerData[1].state == NetworkManager.PeerState.CONNECTED
    end)
end

PacketHandlerClient[HelloPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    -- HANDSHAKE: 3) Client AUTH
    local peerData = nm.peerData[1]

    if peerData.state ~= NetworkManager.PeerState.CONNECTED then
        nm:DisconnectWithReason(1, "Incorrect stage for handshake begin")
    end

    local hp = packet :: HelloPacket.HelloPacketServer

    local map = MapManager.maps[hp.mapId]

    if not map then
        nm:DisconnectWithReason(1, "Client doesn't have requested map")
        return
    end

    if map.manifest.version ~= hp.mapVersion then
        nm:DisconnectWithReason(1, "Client map version mismatch")
        return
    end

    if map.hash ~= hp.mapHash then
        nm:DisconnectWithReason(1, "Client map hash mismatch")
        return
    end

    MapManager:Load(hp.mapId)

    local auth = AuthPacket.client.new()

    if bit32.band(hp.authType, AuthPacket.AuthType.PASSWORD) ~= 0 then
        auth.password = nm.password
    end

    nm:SendPacket(1, auth)

    peerData.state = NetworkManager.PeerState.AUTH
    nm:DisconnectTimeout(1, function()
        return peerData.state == NetworkManager.PeerState.AUTH
    end)
end

PacketHandlerClient[PeerStatusPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    local peerData = nm.peerData[1]
    local psp = packet :: PeerStatusPacket.PeerStatusPacket

    if psp.status == PeerStatusPacket.PeerStatus.JOIN then
        if psp.peer == nm.peer:GetUniqueId() then
            -- HANDSHAKE: 5) End
            if peerData.state ~= NetworkManager.PeerState.AUTH then
                nm:DisconnectWithReason(1, "Incorrect stage for join status")
            end

            peerData.state = NetworkManager.PeerState.JOINED
            nm:Log(`successfully joined as {psp.identity}`)
        else
            nm:Log(`peer {psp.peer} joined as {psp.identity}`)
            nm.peerData[psp.peer] = {
                state = NetworkManager.PeerState.JOINED,
                identity = psp.identity,
                successfulPings = 0,
                rtt = 0,
            }
        end
    else
        if psp.peer == nm.peer:GetUniqueId() then
            return
        end

        nm:Log(`peer {psp.peer} ({psp.identity}) left`)
        nm.peerData[psp.peer] = nil
    end
end

return PacketHandlerClient
