class_name ModuleManifest
extends Resource
## A module manifest resource that extends Godot's [code]plugin.cfg[/code].
##
## It should be placed alongside it in a file called [code]module.tres[/code].

## Dependencies of this module, where the key is the name of the dependency and
## the value is its configuration (or [code]null[/code]).
@export var dependencies: Dictionary[StringName, Variant] = {
	"@fumohouse/base": null,
}

## The scene to use when using this module as an entry point.
@export_file("*.tscn") var entry_scene := ""

## The scenes/scripts to automatically load as singletons, where the key is the
## name of the singleton and the value is the path to the scene/script.
@export var autoloads: Dictionary[StringName, String] = {}
