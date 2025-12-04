class_name FumoAppearances
extends Node

signal active_changed(Appearance: Appearance)

signal staging_changed(Appearance: Appearance)

signal entries_updated

var _active: Appearance = preload(
	"res://addons/@fumohouse/fumo_models/resources/presets/doremy.tres"
)

var _staging: Appearance = _active.duplicate(true)

var entries: Array[Appearance]


static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances

func _ready():
	scan_dir("res://addons/@fumohouse/fumo_models/resources/presets")
	entries_updated.emit()


## Scan [param dir] recursively for model presets.
# Remember to call [code]entries_updated.emit()[/code], after scanning multiple directories
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


# Modify staging Appearance with [param fn], which takes staging as parameter and returns the modified value
func with_staging(fn: Callable):
	_staging = fn.call(_staging)
	staging_changed.emit(_staging)


# Apply active Appearance by copying from staging
func apply():
	_active = _staging.duplicate(true)
	active_changed.emit(_active)
