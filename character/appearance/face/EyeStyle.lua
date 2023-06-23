--- @class EyeStyle
--- @extends Resource
local EyeStyle = {}
local EyeStyleC = gdclass(EyeStyle)

--- @classType EyeStyle
export type EyeStyle = Resource & typeof(EyeStyle) & {
    --- @property
    name: string,

    --- @property
    eyes: Texture2D,

    --- @property
    shine: Texture2D,

    --- @property
    overlay: Texture2D,

    --- @property
    --- @default true
    supportsRecoloring: boolean,
}

return EyeStyleC
