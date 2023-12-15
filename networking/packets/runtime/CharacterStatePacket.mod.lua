local SerDe = require("../../SerDe.mod")

local CharacterAppearanceFragment = require("CharacterAppearanceFragment.mod")
local Appearance = require("../../../character/appearance/Appearance")

local CharacterStateUpdateType = {
    SPAWN = 0,
    MOVEMENT = 1,
    APPEARANCE = 2,
    DELETE = 3,
}

local CharacterStatePacket = { NAME = "RNT.CHR.STU", MODE = nil, CHANNEL = nil }
CharacterStatePacket.__index = CharacterStatePacket

function CharacterStatePacket.new(type: number?, peer: number?)
    return setmetatable({
        type = type or CharacterStateUpdateType.SPAWN,
        peer = peer or 0,

        transform = Transform3D.new(),

        state = 0,
        isRagdoll = false,
        movementAck = 0,
        direction = Vector2.ZERO,
        movementFlags = 0,
        cameraRotation = Vector2.ZERO,
        cameraMode = 0,

        appearance = nil :: Appearance.Appearance?,

        died = false,
    }, CharacterStatePacket)
end

function CharacterStatePacket.SerDe(self: CharacterStatePacket, serde: SerDe.SerDe)
    self.type = serde:SerDe(self.type, SerDe.NumberType.U8)
    self.peer = serde:SerDe(self.peer, SerDe.NumberType.S32)

    if self.type == CharacterStateUpdateType.SPAWN or self.type == CharacterStateUpdateType.MOVEMENT then
        self.transform = serde:SerDe(self.transform)
    end

    if self.type == CharacterStateUpdateType.MOVEMENT then
        self.state = serde:SerDe(self.state, SerDe.NumberType.U16)
        self.isRagdoll = serde:SerDe(self.isRagdoll)

        self.movementAck = serde:SerDe(self.movementAck, SerDe.NumberType.U64)

        self.direction = serde:SerDe(self.direction)
        self.movementFlags = serde:SerDe(self.movementFlags, SerDe.NumberType.U8)

        self.cameraRotation = serde:SerDe(self.cameraRotation)
        self.cameraMode = serde:SerDe(self.cameraMode, SerDe.NumberType.S32)
    end

    if self.type == CharacterStateUpdateType.SPAWN or self.type == CharacterStateUpdateType.APPEARANCE then
        local appearance = CharacterAppearanceFragment.client.new(self.appearance)
        appearance:SerDe(serde)

        self.appearance = appearance.appearance
    end

    if self.type == CharacterStateUpdateType.DELETE then
        self.died = serde:SerDe(self.died)
    end
end

export type CharacterStatePacket = typeof(CharacterStatePacket.new())

return {
    CharacterStateUpdateType = CharacterStateUpdateType,
    server = CharacterStatePacket,
}
