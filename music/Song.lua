local MusicResBase = require("MusicResBase")
local SongArtist = require("SongArtist")
local SongLabel = require("SongLabel")

--- @class Song
--- @extends MusicResBase
local Song = {}
local SongC = gdclass(Song)

export type Song = MusicResBase.MusicResBase & typeof(Song) & {
    --- @property
    id: string,

    --- @property
    artist: SongArtist.SongArtist,
    --- @property
    label: SongLabel.SongLabel?,

    --- @property
    --- @file *.ogg *.mp3 *.wav
    path: string,
}

return SongC
