local SerDe = require("../SerDe.mod")

local GoodbyePacket = { NAME = "GOODBYE", MODE = nil, CHANNEL = nil }
GoodbyePacket.__index = GoodbyePacket

function GoodbyePacket.new(reason: string?)
    return setmetatable({
        reason = reason or "",
    }, GoodbyePacket)
end

function GoodbyePacket.SerDe(self: GoodbyePacket, serde: SerDe.SerDe)
    self.reason = serde:SerDe(self.reason)
end

export type GoodbyePacket = typeof(GoodbyePacket.new())

return {
    client = GoodbyePacket,
    server = GoodbyePacket,
}
