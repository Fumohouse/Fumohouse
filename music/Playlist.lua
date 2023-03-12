local Song = require("Song")

local Playlist = gdclass("Playlist", Resource)

export type Playlist = Resource & {
    id: string,
    songs: TypedArray<Song.Song>,
}

Playlist:RegisterProperty("id", Enum.VariantType.STRING)

Playlist:RegisterProperty("songs", Enum.VariantType.ARRAY)
    :TypedArray(Song)

return Playlist
