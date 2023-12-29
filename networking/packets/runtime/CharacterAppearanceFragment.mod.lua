local SerDe = require("../../SerDe.mod")

local Appearance = require("../../../character/appearance/Appearance")

local CharacterAppearanceFragment = { NAME = "RNT.CHR.APR", MODE = nil, CHANNEL = nil }
CharacterAppearanceFragment.__index = CharacterAppearanceFragment

function CharacterAppearanceFragment.new(appearance: Appearance.Appearance?)
    return setmetatable({
        appearance = appearance or Appearance.new() :: Appearance.Appearance,
    }, CharacterAppearanceFragment)
end

function CharacterAppearanceFragment.SerDe(self: CharacterAppearanceFragment, serde: SerDe.SerDe)
    local appearance = self.appearance

    appearance.name = serde:SerDe(appearance.name)
    appearance.eyebrows = serde:SerDe(appearance.eyebrows)
    appearance.eyes = serde:SerDe(appearance.eyes)
    appearance.mouth = serde:SerDe(appearance.mouth)
    appearance.eyesColor = serde:SerDe(appearance.eyesColor)
    appearance.scale = serde:SerDe(appearance.scale, SerDe.NumberType.FLOAT)
    appearance.attachedParts = serde:SerDe(appearance.attachedParts)
end

export type CharacterAppearanceFragment = typeof(CharacterAppearanceFragment.new())

return {
    client = CharacterAppearanceFragment,
    server = CharacterAppearanceFragment,
}
