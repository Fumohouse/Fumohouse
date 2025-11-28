class_name WorldManifest
extends ModuleManifest
## A world manifest resource that extends [ModuleManifest] and marks the
## enclosing module as a playable world.
##
## It should be placed in the same location as other modules,
## [code]module.tres[/code].

## User-facing name of the world.
@export var display_name := ""

## Music playlists to load for this world.
@export var playlists: Array[Playlist] = []
## The ID of the music playlist to be used on the title screen, if applicable.
@export var title_playlist := &""
## The ID of the music playlist to be used by default ingame (i.e., when not in
## any playlist region).
@export var default_playlist := &""
