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
## Emitted after [member presets] is updated.
signal presets_updated

## Current appearance for local character
##
## After modifying this value or its fields, it is recommended to emit the
## [signal active_changed] signal to notify listeners.
var active: Appearance = preload(
	"res://addons/@fumohouse/fumo_models/resources/presets/doremy.tres"
)

## Preview appearance to be applied.
##
## After modifying this value or its fields, it is recommended to emit the
## [signal staging_changed] signal to notify listeners.
var staging: Appearance = active.duplicate(true)

## List of presets available.
var presets: Array[Appearance]


## Get the singleton instance for this node.
static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


func _ready():
	scan_dir("res://addons/@fumohouse/fumo_models/resources/presets")


## Scan [param path] recursively for model presets.
func scan_dir(path: String):
	var updated: bool = false

	for entry in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			continue

		var preset := load(path.path_join(entry)) as Appearance
		if not preset:
			push_warning("Unrecognized preset: '%s'." % entry)
			continue

		presets.push_back(preset)
		updated = true

	if updated:
		presets.sort_custom(
			func(a: Appearance, b: Appearance): return a.display_name < b.display_name
		)
		presets_updated.emit()


## Apply active [Appearance] by copying from staging.
func apply():
	active = staging.duplicate(true)
	active_changed.emit()
