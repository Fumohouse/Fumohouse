--- @class FacePartStyle
--- @extends Resource
local FacePartStyle = {}
local FacePartStyleC = gdclass(FacePartStyle)

export type FacePartStyle = Resource & typeof(FacePartStyle) & {
    --- @property
    name: string,

    --- @property
    texture: Texture2D,
}

return FacePartStyleC
