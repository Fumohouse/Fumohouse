local MusicResBase = require("MusicResBase")
local SongArtist = require("SongArtist")
local SongLabel = require("SongLabel")

local Song = gdclass("Song", MusicResBase)

export type Song = MusicResBase.MusicResBase & {
    id: string,

    artist: SongArtist.SongArtist,
    label: SongLabel.SongLabel?,

    path: string,
}

Song:RegisterProperty("id", Enum.VariantType.STRING)

Song:RegisterProperty("artist", Enum.VariantType.OBJECT)
    :Resource("SongArtist")

Song:RegisterProperty("label", Enum.VariantType.OBJECT)
    :Resource("SongLabel")

Song:RegisterProperty("path", Enum.VariantType.STRING)
    :File(false, "*.ogg", "*.mp3", "*.wav")

return Song
