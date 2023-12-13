local SerDe = require("../SerDe.mod")

export type PacketImpl = {
    __index: PacketImpl,

    NAME: string,
    MODE: number?,
    CHANNEL: number?,

    SerDe: (self: Packet, serde: SerDe.SerDe) -> (),

    [any]: any,
}

export type Packet = typeof(setmetatable({}, {} :: PacketImpl))

local PacketTypes = {
    require("HelloPacket.mod") :: any,
    require("AuthPacket.mod") :: any,
    require("PeerStatusPacket.mod") :: any,
    require("GoodbyePacket.mod") :: any,
    require("PingPacket.mod") :: any,
}

local Id = {}

for i, packet in PacketTypes do
    if packet.client then
        Id[packet.client.NAME] = i
    end

    if packet.server then
        Id[packet.server.NAME] = i
    end
end

return {
    PacketTypes = PacketTypes,
    Id = Id,
}
