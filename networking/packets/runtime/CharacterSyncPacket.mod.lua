local SerDe = require("../../SerDe.mod")

local CharacterAppearanceFragment = require("CharacterAppearanceFragment.mod")
local Appearance = require("../../../character/appearance/Appearance")

local CharacterSyncPacket = { NAME = "RNT.CHR.SYN", MODE = nil, CHANNEL = nil }
CharacterSyncPacket.__index = CharacterSyncPacket

function CharacterSyncPacket.new()
    return setmetatable({
        count = 0,
        peers = {} :: {number},
        transforms = {} :: {Transform3D},
        states = {} :: {number},
        isRagdoll = {} :: {boolean},
        appearances = {} :: {Appearance.Appearance},
    }, CharacterSyncPacket)
end

function CharacterSyncPacket.SerDe(self: CharacterSyncPacket, serde: SerDe.SerDe)
    self.count = serde:SerDe(self.count, SerDe.NumberType.U32)

    local placeholderTransform = Transform3D.new()

    for i = 1, self.count do
        self.peers[i] = serde:SerDe(self.peers[i] or 0, SerDe.NumberType.S32)
        self.transforms[i] = serde:SerDe(self.transforms[i] or placeholderTransform)
        self.states[i] = serde:SerDe(self.states[i] or 0, SerDe.NumberType.U16)
        self.isRagdoll[i] = serde:SerDe(self.isRagdoll[i] or false)

        local appearance = CharacterAppearanceFragment.server.new(self.appearances[i])
        appearance:SerDe(serde)

        self.appearances[i] = appearance.appearance
    end
end

export type CharacterSyncPacket = typeof(CharacterSyncPacket.new())

return {
    server = CharacterSyncPacket,
}
