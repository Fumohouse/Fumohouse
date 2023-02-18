local FacePartStyle = gdclass("FacePartStyle", Resource)

export type FacePartStyle = Resource & {
    name: string,
    texture: Texture2D,
}

FacePartStyle:RegisterProperty("name", Enum.VariantType.STRING)
    :Default("MyStyle")

FacePartStyle:RegisterProperty("texture", Enum.VariantType.OBJECT)
    :Resource("Texture2D")

return FacePartStyle
