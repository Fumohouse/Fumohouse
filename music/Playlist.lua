local Song = require("Song")

--- @class Playlist
--- @extends Resource
local Playlist = {}
local PlaylistC = gdclass(Playlist)

--- @classType Playlist
export type Playlist = Resource & {
    --- @property
    id: string,
    --- @property
    songs: TypedArray<Song.Song>,
}

return PlaylistC
