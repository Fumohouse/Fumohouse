local SerDe = require("../SerDe.mod")

local PeerStatus = {
    JOIN = 0,
    LEFT = 1,
}

local PeerStatusPacket = { NAME = "PEER", MODE = nil, CHANNEL = nil  }
PeerStatusPacket.__index = PeerStatusPacket

function PeerStatusPacket.new(status: number?, identity: string?, peer: number?)
    return setmetatable({
        status = status or PeerStatus.JOIN,
        identity = identity or "",
        peer = peer or 0,
    }, PeerStatusPacket)
end

function PeerStatusPacket.SerDe(self: PeerStatusPacket, serde: SerDe.SerDe)
    self.status = serde:SerDe(self.status, SerDe.NumberType.U8)
    self.identity = serde:SerDe(self.identity)
    self.peer = serde:SerDe(self.peer, SerDe.NumberType.S32)
end

export type PeerStatusPacket = typeof(PeerStatusPacket.new())

return {
    PeerStatus = PeerStatus,
    server = PeerStatusPacket,
}
