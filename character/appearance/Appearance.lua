local PartDatabaseM = require("parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

--- @class Appearance
--- @extends Resource
local Appearance = {}
local AppearanceC = gdclass(Appearance)

--- @classType Appearance
export type Appearance = Resource & typeof(Appearance) & {
    --- @property
    name: string,

    --- @property
    eyebrows: string,

    --- @property
    eyes: string,

    --- @property
    mouth: string,

    --- @property
    eyesColor: Color,

    --- @property
    --- @range 0 3 0.25
    --- @default 1.0
    scale: number,

    --- @property
    attachedParts: Dictionary,
}

function Appearance.GetPartsOfScope(self: Appearance, scope: number)
    local parts = {}

    for id: string in self.attachedParts do
        local part = PartDatabase:GetPart(id)

        if part and part.scope == scope then
            table.insert(parts, id)
        end
    end

    return parts
end

function Appearance.CopyFrom(self: Appearance, other: Appearance)
    self.name = other.name
    self.eyebrows = other.eyebrows
    self.eyes = other.eyes
    self.mouth = other.mouth
    self.eyesColor = other.eyesColor
    self.scale = other.scale
    -- Must deep copy to prevent changes to the Dictionary from being global
    self.attachedParts = other.attachedParts:Duplicate(true)
end

return AppearanceC
