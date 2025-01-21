class_name ModuleAutoload
extends Resource
## An autoload of a [ModuleManifest].

## The name of the autoload.
@export var name := &""

## The path to the scene or script.
@export_file("*.tscn", "*.gd") var path := ""
