class_name Song
extends Resource
## Resource containing the metadata for a song.

## A unique ID to assign to this song.
@export var id := &""

## The name of the song, possibly in a non-English language.
@export var name_unicode := ""

## The name of the song, romanized from [member name_unicode]. Do not populate
## this field if the name is already in English.
@export var name_romanized := ""

## A URL pointing to this song.
@export var url := ""

## The artist of this song.
@export var artist: SongArtist

## The label for this song.
@export var label: SongLabel

## The path to the music file.
@export_file("*.ogg", "*.mp3", "*.wav") var path := ""
