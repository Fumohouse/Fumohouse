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
    nm.peerStates[1] = NetworkManager.PeerState.CONNECTED

    local hello = HelloPacket.client.new(Utils.version, nm.identity)
    nm:SendPacket(1, hello)

    nm:DisconnectTimeout(nil, function()
        return nm.peerStates[1] == NetworkManager.PeerState.CONNECTED
    end)
end

PacketHandlerClient[HelloPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    -- HANDSHAKE: 3) Client AUTH
    if nm.peerStates[1] ~= NetworkManager.PeerState.CONNECTED then
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

    nm.peerStates[1] = NetworkManager.PeerState.AUTH
    nm:DisconnectTimeout(1, function()
        return nm.peerStates[1] == NetworkManager.PeerState.AUTH
    end)
end

PacketHandlerClient[PeerStatusPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    local psp = packet :: PeerStatusPacket.PeerStatusPacket

    if psp.status == PeerStatusPacket.PeerStatus.JOIN then
        if psp.peer == nm.peer:GetUniqueId() then
            -- HANDSHAKE: 5) End
            if nm.peerStates[1] ~= NetworkManager.PeerState.AUTH then
                nm:DisconnectWithReason(1, "Incorrect stage for join status")
            end

            nm.peerStates[1] = NetworkManager.PeerState.JOINED
            nm:Log(`successfully joined as {psp.identity}`)
        else
            nm:Log(`peer {psp.peer} joined as {psp.identity}`)
            nm.peerIdentities[psp.peer] = psp.identity
        end
    else
        if psp.peer == nm.peer:GetUniqueId() then
            return
        end

        nm:Log(`peer {psp.peer} ({psp.identity}) left`)
        nm.peerIdentities[psp.peer] = nil
    end
end

return PacketHandlerClient
