class_name SongLabel
extends Resource
## Resource containing metadata for the label (i.e., publisher) of a [Song].

## The name of the label, possibly in a non-English language.
@export var name_unicode := ""

## The name of the label, romanized from [member name_unicode]. Do not populate
## this field if the name is already in English.
@export var name_romanized := ""

## A URL pointing to this label.
@export var url := ""
