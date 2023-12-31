local SerDe = require("../../SerDe.mod")

local CharacterAppearanceFragment = require("CharacterAppearanceFragment.mod")
local Appearance = require("../../../character/appearance/Appearance")

local CharacterStateUpdateType = {
    SPAWN = 0,
    MOVEMENT = 1,
    APPEARANCE = 2,
    DELETE = 3,
}

local CharacterStatePacket = { NAME = "RNT.CHR.STU", MODE = nil, CHANNEL = 1 }
CharacterStatePacket.__index = CharacterStatePacket

function CharacterStatePacket.new(type: number?, peer: number?)
    return setmetatable({
        type = type or CharacterStateUpdateType.SPAWN,
        peer = peer or 0,

        transform = Transform3D.new(),

        state = 0,
        bodyMode = 0,
        processorState = Dictionary.new(),
        isRagdoll = false,
        movementAck = 0,

        velocity = Vector3.new(),
        angularVelocity = Vector3.new(),

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
        self.bodyMode = serde:SerDe(self.bodyMode, SerDe.NumberType.U8)
        self.processorState = serde:SerDe(self.processorState)
        self.isRagdoll = serde:SerDe(self.isRagdoll)

        self.movementAck = serde:SerDe(self.movementAck, SerDe.NumberType.U64)

        if self.isRagdoll then
            self.velocity = serde:SerDe(self.velocity)
            self.angularVelocity = serde:SerDe(self.angularVelocity)
        end
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
