class_name Playlist
extends Resource
## A playlist of multiple [Song]s.

## A unique ID to assign to this playlist.
@export var id := &""

## The [Song]s in this playlist.
@export var songs: Array[Song] = []
