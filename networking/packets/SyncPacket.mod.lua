local SerDe = require("../SerDe.mod")

local SyncPacket = { NAME = "SYN", MODE = nil, CHANNEL = nil }
SyncPacket.__index = SyncPacket

function SyncPacket.new()
    return setmetatable({
        playerCount = 0,
        peers = {} :: {number},
        identities = {} :: {string},
    }, SyncPacket)
end

function SyncPacket.SerDe(self: SyncPacket, serde: SerDe.SerDe)
    self.playerCount = serde:SerDe(self.playerCount, SerDe.NumberType.U32)

    for i = 1, self.playerCount do
        self.peers[i] = serde:SerDe(self.peers[i] or 0, SerDe.NumberType.S32)
        self.identities[i] = serde:SerDe(self.identities[i] or "")
    end
end

export type SyncPacket = typeof(SyncPacket.new())

return {
    server = SyncPacket,
}
