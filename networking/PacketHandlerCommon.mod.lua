local NetworkManager = require("NetworkManager")
local Packet = require("packets/Packet.mod")

local GoodbyePacket = require("packets/GoodbyePacket.mod")
local PingPacket = require("packets/PingPacket.mod")

local PacketHandlerCommon = {}

PacketHandlerCommon[GoodbyePacket.client.NAME] = function(nm: NetworkManager.NetworkManager, peer: number, packet: Packet.Packet)
    local gp = packet :: GoodbyePacket.GoodbyePacket
    nm:Log(`peer {peer} disconnected: {gp.reason}`)

    if nm.isServer then
        nm.multiplayer:DisconnectPeer(peer)
    else
        nm:Reset()
        nm:sendStatusUpdate(`Kicked: {gp.reason}`, true, false)
    end
end

PacketHandlerCommon[PingPacket.client.NAME] = function(nm: NetworkManager.NetworkManager, peer: number, packet: Packet.Packet)
    local pp = packet :: PingPacket.PingPacket

    if pp.pong then
        local now = Time.singleton:GetTicksUsec()
        local rtt = (now - pp.payload) / 1000
        nm.peerData[peer].rtt = rtt
        nm.peerData[peer].successfulPings += 1
    else
        local pong = PingPacket.server.new(true, pp.payload)
        nm:SendPacket(peer, pong)
    end
end

return PacketHandlerCommon
