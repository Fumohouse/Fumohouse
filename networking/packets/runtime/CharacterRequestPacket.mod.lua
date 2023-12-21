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

        userdata = 0,
        direction = Vector2.ZERO,
        movementFlags = MovementFlags.NONE,
        cameraRotation = Vector2.ZERO,
        cameraMode = 0,

        appearance = nil :: Appearance.Appearance?,

        died = false,
    }, CharacterRequestPacket)
end

function CharacterRequestPacket.SerDe(self: CharacterRequestPacket, serde: SerDe.SerDe)
    self.type = serde:SerDe(self.type, SerDe.NumberType.U8)

    if self.type == CharacterStatePacket.CharacterStateUpdateType.MOVEMENT then
        self.userdata = serde:SerDe(self.userdata or 0, SerDe.NumberType.U64)

        local idleValue = self.direction == Vector2.ZERO and self.movementFlags == MovementFlags.NONE
        local idle = serde:SerDe(idleValue)

        if not idle then
            self.direction = serde:SerDe(self.direction)
            self.movementFlags = serde:SerDe(self.movementFlags, SerDe.NumberType.U8)
        end

        self.cameraRotation = serde:SerDe(self.cameraRotation)
        self.cameraMode = serde:SerDe(self.cameraMode)
    end

    if self.type == CharacterStatePacket.CharacterStateUpdateType.SPAWN or
        self.type == CharacterStatePacket.CharacterStateUpdateType.APPEARANCE then
        local appearance = CharacterAppearanceFragment.client.new(self.appearance)
        appearance:SerDe(serde)

        self.appearance = appearance.appearance
    end

    if self.type == CharacterStatePacket.CharacterStateUpdateType.DELETE then
        self.died = serde:SerDe(self.died)
    end
end

export type CharacterRequestPacket = typeof(CharacterRequestPacket.new())

return {
    MovementFlags = MovementFlags,
    client = CharacterRequestPacket,
}
