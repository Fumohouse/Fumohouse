class_name FumoAppearances
extends Node
## Class for Fumo appearances for the local character
##
## Keeps track of active and staging appearances, to use in-game and when
## editing respectively

signal active_changed(Appearance: Appearance)

signal staging_changed(Appearance: Appearance)

signal entries_updated

## Current appearance for local character
var active: Appearance = preload(
	"res://addons/@fumohouse/fumo_models/resources/presets/doremy.tres"
)

## Appearance to be applied.
##
## Prefer to use [method with_staging] to set fields and to automatically emit
## [signal staging_changed]
var staging: Appearance = active.duplicate(true)

var entries: Array[Appearance]


static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


func _ready():
	scan_dir("res://addons/@fumohouse/fumo_models/resources/presets")
	entries_updated.emit()


## Scan [param dir] recursively for model presets.
## Remember to call [code]entries_updated.emit()[/code], after scanning
## multiple directories
func scan_dir(path: String):
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Failed to open presets directory.")
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

		entries.push_front(preset)


## Modify staging Appearance with [param fn], which takes staging as parameter
func with_staging(fn: Callable):
	fn.call(staging)
	staging_emit()


## Notify of changes to [member staging], when modifying fields directly
func staging_emit():
	staging_changed.emit(staging)


## Apply active Appearance by copying from staging
func apply():
	active = staging.duplicate(true)
	active_changed.emit(active)
