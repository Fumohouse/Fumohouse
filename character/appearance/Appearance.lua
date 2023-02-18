local Appearance = gdclass("Appearance", Resource)

export type Appearance = Resource & {
    eyebrows: string,
    eyes: string,
    mouth: string,
    eyesColor: Color,

    size: string,

    attachedParts: Dictionary,
}

Appearance:RegisterProperty("eyebrows", Enum.VariantType.STRING)
Appearance:RegisterProperty("eyes", Enum.VariantType.STRING)
Appearance:RegisterProperty("mouth", Enum.VariantType.STRING)
Appearance:RegisterProperty("eyesColor", Enum.VariantType.COLOR)

Appearance:RegisterProperty("size", Enum.VariantType.STRING)

Appearance:RegisterProperty("attachedParts", Enum.VariantType.DICTIONARY)

return Appearance
