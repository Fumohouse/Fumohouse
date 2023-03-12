local EyeStyle = gdclass("EyeStyle", Resource)

export type EyeStyle = Resource & {
    name: string,
    eyes: Texture2D,
    shine: Texture2D,
    overlay: Texture2D,
    supportsRecoloring: boolean,
}

EyeStyle:RegisterProperty("name", Enum.VariantType.STRING)

EyeStyle:RegisterProperty("eyes", Enum.VariantType.OBJECT)
    :Resource(Texture2D)

EyeStyle:RegisterProperty("shine", Enum.VariantType.OBJECT)
    :Resource(Texture2D)

EyeStyle:RegisterProperty("overlay", Enum.VariantType.OBJECT)
    :Resource(Texture2D)

EyeStyle:RegisterProperty("supportsRecoloring", Enum.VariantType.BOOL)
    :Default(true)

return EyeStyle
