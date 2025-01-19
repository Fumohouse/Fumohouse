class_name ModuleManifest
extends Resource
## A module manifest resource that extends Godot's [code]plugin.cfg[/code].
##
## It should be placed alongside it in a file called [code]module.tres[/code].

## Dependencies of this module. It is assumed that all modules depend on
## [code]@fumohouse/base[/code].
@export var dependencies: Array[ModuleDependency] = []

## The scene to use when using this module as an entry point.
@export_file("*.tscn") var entry_scene := ""

## The scenes/scripts to automatically load as singletons, where the key is the
## name of the singleton and the value is the path to the scene/script.
@export var autoloads: Dictionary[StringName, String] = {}
