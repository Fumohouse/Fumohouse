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

## The scenes/scripts to automatically load as singletons.
@export var autoloads: Array[ModuleAutoload] = []

## Name of this module (e.g., [code]@fumohouse/base[/code]), populated by the
## module manager.
var name := &""
## Description of this module, populated by the module manager.
var description := ""
## Author of this module, populated by the module manager.
var author := ""
## Version of this module, populated by the module manager.
var version := ""
