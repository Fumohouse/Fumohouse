local PartDatabaseM = require("parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

local AppearanceImpl = {}
local Appearance = gdclass("Appearance", Resource)
    :RegisterImpl(AppearanceImpl)

type AppearanceT = {
    eyebrows: string,
    eyes: string,
    mouth: string,
    eyesColor: Color,

    scale: number,

    attachedParts: Dictionary,
}

export type Appearance = Resource & AppearanceT & typeof(AppearanceImpl)

Appearance:RegisterProperty("eyebrows", Enum.VariantType.STRING)
Appearance:RegisterProperty("eyes", Enum.VariantType.STRING)
Appearance:RegisterProperty("mouth", Enum.VariantType.STRING)
Appearance:RegisterProperty("eyesColor", Enum.VariantType.COLOR)

Appearance:RegisterProperty("scale", Enum.VariantType.FLOAT)
    :Range(0, 3, 0.25)
    :Default(1)

Appearance:RegisterProperty("attachedParts", Enum.VariantType.DICTIONARY)

function AppearanceImpl.GetPartOfScope(self: Appearance, scope: number): string?
    for id: string in self.attachedParts do
        local part = PartDatabase:GetPart(id)

        if part and part.scope == scope then
            return id
        end
    end

    return nil
end

return Appearance
