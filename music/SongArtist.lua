local MusicResBase = require("MusicResBase")

--- @class SongArtist
--- @extends MusicResBase
local SongArtist = {}
local SongArtistC = gdclass(SongArtist)

--- @classType SongArtist
export type SongArtist = MusicResBase.MusicResBase

return SongArtistC
