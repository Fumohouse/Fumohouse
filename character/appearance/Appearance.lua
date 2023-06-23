local PartDatabaseM = require("parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

--- @class Appearance
--- @extends Resource
local Appearance = {}
local AppearanceC = gdclass(Appearance)

--- @classType Appearance
export type Appearance = Resource & typeof(Appearance) & {
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

function Appearance.GetPartOfScope(self: Appearance, scope: number): string?
    for id: string in self.attachedParts do
        local part = PartDatabase:GetPart(id)

        if part and part.scope == scope then
            return id
        end
    end

    return nil
end

return AppearanceC
