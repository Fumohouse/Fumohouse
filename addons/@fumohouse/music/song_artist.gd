class_name SongArtist
extends Resource
## Resource containing metadata for the artist of a [Song].

## The name of the artist, possibly in a non-English language.
@export var name_unicode := ""

## The name of the artist, romanized from [member name_unicode]. Do not populate
## this field if the name is already in English.
@export var name_romanized := ""

## A URL pointing to this artist.
@export var url := ""
