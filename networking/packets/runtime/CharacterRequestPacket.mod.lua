local SerDe = require("../../SerDe.mod")

local CharacterStatePacket = require("CharacterStatePacket.mod")
local CharacterAppearanceFragment = require("CharacterAppearanceFragment.mod")
local Appearance = require("../../../character/appearance/Appearance")

local MovementFlags = {
    NONE = 0,
    JUMP = 1,
    RUN = 2,
    SIT = 4,
}

local CharacterRequestPacket = { NAME = "RNT.CHR.REQ", MODE = nil, CHANNEL = nil }
CharacterRequestPacket.__index = CharacterRequestPacket

function CharacterRequestPacket.new(type: number?)
    return setmetatable({
        type = type or CharacterStatePacket.CharacterStateUpdateType.SPAWN,

        count = 0,
        userdata = {} :: {number},
        direction = {} :: {Vector2},
        movementFlags = {} :: {number},
        cameraRotation = {} :: {Vector2},
        cameraMode = {} :: {number},

        appearance = nil :: Appearance.Appearance?,
    }, CharacterRequestPacket)
end

function CharacterRequestPacket.SerDe(self: CharacterRequestPacket, serde: SerDe.SerDe)
    self.type = serde:SerDe(self.type, SerDe.NumberType.U8)

    if self.type == CharacterStatePacket.CharacterStateUpdateType.MOVEMENT then
        self.count = serde:SerDe(self.count, SerDe.NumberType.U32)

        for i = 1, self.count do
            self.userdata[i] = serde:SerDe(self.userdata[i] or 0, SerDe.NumberType.U64)
            self.direction[i] = serde:SerDe(self.direction[i] or Vector2.ZERO)
            self.movementFlags[i] = serde:SerDe(self.movementFlags[i], SerDe.NumberType.U8)
            self.cameraRotation[i] = serde:SerDe(self.cameraRotation[i] or Vector2.ZERO)
            self.cameraMode[i] = serde:SerDe(self.cameraMode[i] or 0, SerDe.NumberType.U8)
        end
    end

    if self.type == CharacterStatePacket.CharacterStateUpdateType.SPAWN or
        self.type == CharacterStatePacket.CharacterStateUpdateType.APPEARANCE then
        local appearance = CharacterAppearanceFragment.client.new(self.appearance)
        appearance:SerDe(serde)

        self.appearance = appearance.appearance
    end
end

export type CharacterRequestPacket = typeof(CharacterRequestPacket.new())

return {
    MovementFlags = MovementFlags,
    client = CharacterRequestPacket,
}
