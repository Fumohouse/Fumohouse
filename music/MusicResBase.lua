local MusicResBase = gdclass("MusicResBase", Resource)

export type MusicResBase = Resource & {
    nameUnicode: string,
    nameRomanized: string,
    url: string,
}

MusicResBase:RegisterProperty("nameUnicode", Enum.VariantType.STRING)
MusicResBase:RegisterProperty("nameRomanized", Enum.VariantType.STRING)
MusicResBase:RegisterProperty("url", Enum.VariantType.STRING)

return MusicResBase
