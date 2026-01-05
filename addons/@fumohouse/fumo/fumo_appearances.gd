class_name FumoAppearances
extends Node
## Singleton to keep track of Fumo appearance presets and to manage presets for
## the local character.
##
## Keeps track of active and staging appearances, to use in-game and when
## editing respectively.

## Emitted after [member active] changes.
signal active_changed
## Emitted after [member staging] changes.
signal staging_changed

## Current appearance for local character. Default value is injected by
## [code]@fumohouse/fumo_touhou[/code].
var active: Appearance

## Cache of part configuration, keyed by part ID.
var part_config_cache: Dictionary[StringName, Dictionary] = {}

## Preview appearance to be applied. Default value is injected by
## [code]@fumohouse/fumo_touhou[/code].
##
## After modifying this value or its fields, it is recommended to emit the
## [signal staging_changed] signal to notify listeners.
var staging: Appearance

## List of presets available.
var presets: Array[Appearance]


## Get the singleton instance for this node.
static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


func _ready():
	presets.sort_custom(func(a: Appearance, b: Appearance): return a.display_name < b.display_name)


## Scan [param path] recursively for model presets.
func scan_dir(path: String):
	for entry in ResourceLoader.list_directory(path):
		var full_path := path.path_join(entry)
		if entry.ends_with("/"):
			scan_dir(full_path)
			continue

		var preset := load(full_path) as Appearance
		if not preset:
			push_warning("Unrecognized preset: '%s'." % full_path)
			continue

		presets.push_back(preset)


## Apply active [Appearance] by copying from staging.
func apply():
	active = staging.duplicate(true)
	active_changed.emit()
