class_name FumoAppearances
extends Node
## Singleton to keep track of Fumo appearance presets and to manage presets
## for the local character.
##
## Keeps track of active and staging appearances, to use in-game and when
## editing respectively.

## Emitted after [member active] changes.
signal active_changed(new_active: Appearance)
## Emitted after [member staging] changes.
signal staging_changed(new_staging: Appearance)
## Emitted after [member presets] is updated.
signal presets_updated

## Current appearance for local character
##
## After modifying this value or its fields, it is recommended to call
## [method active_emit] to notify listeners.
var active: Appearance = preload(
	"res://addons/@fumohouse/fumo_models/resources/presets/doremy.tres"
)

## Preview appearance to be applied.
##
## After modifying this value or its fields, it is recommended to call
## [method staging_emit] to notify listeners.
var staging: Appearance = active.duplicate(true)

## List of presets available.
var presets: Array[Appearance]


## Get the singleton instance for this node.
static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


func _ready():
	scan_dir("res://addons/@fumohouse/fumo_models/resources/presets")


## Scan [param dir] recursively for model presets.
## Remember to call [code]entries_updated.emit()[/code], after scanning
## multiple directories
func scan_dir(path: String):
	var updated: bool = false

	var dir := DirAccess.open(path)
	if not dir:
		push_error("Failed to open presets directory: '%'." % DirAccess.get_open_error())
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break

		if dir.current_is_dir():
			scan_dir(path.path_join(file_name))
			continue

		var preset := load(path.path_join(file_name)) as Appearance
		if not preset:
			push_warning("Unrecognized preset: '%s'." % file_name)
			continue

		presets.push_front(preset)
		updated = true

	if updated:
		presets.sort_custom(
			func(a: Appearance, b: Appearance): return a.display_name < b.display_name
		)
		presets_updated.emit()


## Notify of changes to [member active].
func active_emit():
	active_changed.emit(staging)


## Notify of changes to [member staging].
func staging_emit():
	staging_changed.emit(staging)


## Apply active Appearance by copying from staging.
func apply():
	active = staging.duplicate(true)
	active_changed.emit(active)
