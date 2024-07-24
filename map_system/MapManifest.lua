local Playlist = require("../music/Playlist")

--- @class MapManifest
--- @extends Resource
local MapManifest = {}
local MapManifestC = gdclass(MapManifest)

export type MapManifest = Resource & typeof(MapManifest) & {
    --- @property
    id: string,
    --- @property
    name: string,
    --- @property
    version: string,
    --- @property
    author: string,

    --- @property
    --- @multiline
    description: string,

    --- @property
    --- @file *.tscn
    mainScenePath: string,

    --- @property
    playlists: TypedArray<Playlist.Playlist>,
    --- @property
    titlePlaylist: string,
    --- @property
    defaultPlaylist: string,

    --- @property
    --- @file *.txt
    copyrightFile: string,
}

return MapManifestC
