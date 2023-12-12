local SerDe = require("../SerDe.mod")

local AuthType = {
    NONE = 0,
    PASSWORD = 1,
}

local AuthPacket = { NAME = "AUTH", MODE = nil, CHANNEL = nil  }
AuthPacket.__index = AuthPacket

function AuthPacket.new()
    return setmetatable({
        password = "",
    }, AuthPacket)
end

function AuthPacket.SerDe(self: AuthPacket, serde: SerDe.SerDe)
    self.password = serde:SerDe(self.password)
end

export type AuthPacket = typeof(AuthPacket.new())

return {
    AuthType = AuthType,
    client = AuthPacket,
}
