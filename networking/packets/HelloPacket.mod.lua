local AuthPacket = require("AuthPacket.mod")
local SerDe = require("../SerDe.mod")

local HelloPacketClient = { NAME = "HELLO", MODE = nil, CHANNEL = nil  }
HelloPacketClient.__index = HelloPacketClient

function HelloPacketClient.new(version: string?, identity: string?)
    return setmetatable({
        version = version or "",
        identity = identity or "",
    }, HelloPacketClient)
end

function HelloPacketClient.SerDe(self: HelloPacketClient, serde: SerDe.SerDe)
    self.version = serde:SerDe(self.version)
    self.identity = serde:SerDe(self.identity)
end

export type HelloPacketClient = typeof(HelloPacketClient.new())

local HelloPacketServer = { NAME = "HELLO", MODE = nil, CHANNEL = nil  }
HelloPacketServer.__index = HelloPacketServer

function HelloPacketServer.new(authType: number?, mapId: string?, mapVersion: string?, mapHash: string?)
    return setmetatable({
        authType = authType or AuthPacket.AuthType.NONE,

        mapId = mapId or "",
        mapVersion = mapVersion or "",
        mapHash = mapHash or "",
    }, HelloPacketServer)
end

function HelloPacketServer.SerDe(self: HelloPacketServer, serde: SerDe.SerDe)
    self.authType = serde:SerDe(self.authType, SerDe.NumberType.U8)

    self.mapId = serde:SerDe(self.mapId)
    self.mapVersion = serde:SerDe(self.mapVersion)
    self.mapHash = serde:SerDe(self.mapHash)
end

export type HelloPacketServer = typeof(HelloPacketServer.new())

return {
    client = HelloPacketClient,
    server = HelloPacketServer,
}
