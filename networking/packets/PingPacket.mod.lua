local SerDe = require("../SerDe.mod")

local PingPacket = { NAME = "PING", MODE = nil, CHANNEL = nil }
PingPacket.__index = PingPacket

function PingPacket.new(pong: boolean?, payload: number?)
    return setmetatable({
        pong = pong or false,
        payload = payload or 0,
    }, PingPacket)
end

function PingPacket.SerDe(self: PingPacket, serde: SerDe.SerDe)
    self.pong = serde:SerDe(self.pong)
    self.payload = serde:SerDe(self.payload, SerDe.NumberType.U64)
end

export type PingPacket = typeof(PingPacket.new())

return {
    client = PingPacket,
    server = PingPacket,
}
