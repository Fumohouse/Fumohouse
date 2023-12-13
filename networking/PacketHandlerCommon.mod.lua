local NetworkManager = require("NetworkManager")
local Packet = require("packets/Packet.mod")

local GoodbyePacket = require("packets/GoodbyePacket.mod")

local PacketHandlerCommon = {}

PacketHandlerCommon[GoodbyePacket.client.NAME] = function(nm: NetworkManager.NetworkManager, peer: number, packet: Packet.Packet)
    local gp = packet :: GoodbyePacket.GoodbyePacket
    nm:Log(`peer {peer} disconnected: {gp.reason}`)

    if nm.isServer then
        nm.multiplayer:DisconnectPeer(peer)
    else
        nm:Reset()
    end
end

return PacketHandlerCommon
