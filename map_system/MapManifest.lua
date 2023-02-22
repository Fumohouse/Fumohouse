local Playlist = require("../music/Playlist")

local MapManifest = gdclass("MapManifest", Resource)

export type MapManifest = Resource & {
    id: string,

    name: string,
    author: string,
    description: string,

    mainScenePath: string,
    playlists: TypedArray<Playlist.Playlist>,

    titlePlaylist: string,
    defaultPlaylist: string,
}

MapManifest:RegisterProperty("id", Enum.VariantType.STRING)
MapManifest:RegisterProperty("name", Enum.VariantType.STRING)

MapManifest:RegisterProperty("author", Enum.VariantType.STRING)

MapManifest:RegisterProperty("description", Enum.VariantType.STRING)
    :Multiline()

MapManifest:RegisterProperty("mainScenePath", Enum.VariantType.STRING)
    :File(false, "*.tscn")

MapManifest:RegisterProperty("playlists", Enum.VariantType.ARRAY)
    :TypedArray("Playlist", true)

MapManifest:RegisterProperty("titlePlaylist", Enum.VariantType.STRING)
MapManifest:RegisterProperty("defaultPlaylist", Enum.VariantType.STRING)

return MapManifest
