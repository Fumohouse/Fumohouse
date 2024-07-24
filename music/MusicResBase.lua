--- @class MusicResBase
--- @extends Resource
local MusicResBase = {}
local MusicResBaseC = gdclass(MusicResBase)

export type MusicResBase = Resource & typeof(MusicResBase) & {
    --- @property
    nameUnicode: string,
    --- @property
    nameRomanized: string,
    --- @property
    url: string,
}

return MusicResBaseC
