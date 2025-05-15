class_name Song
extends "./res_base.gd"
## Resource containing the metadata for a song.

## A unique ID to assign to this song.
@export var id := &""

## The artist of this song.
@export var artist: SongArtist

## The label for this song.
@export var label: SongLabel

## The path to the music file.
@export_file("*.ogg", "*.mp3", "*.wav") var path := ""
