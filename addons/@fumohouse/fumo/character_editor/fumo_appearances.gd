class_name FumoAppearances
extends Node

signal current_changed(Appearance: Appearance)

signal staging_changed(Appearance: Appearance)

var _current: Appearance = preload(
	"res://addons/@fumohouse/fumo_models/resources/presets/doremy.tres"
)

var _staging: Appearance


static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


# Modify staging Appearance with [param fn] with staging as parameter and returning the new value
func change_staging(fn: Callable):
	_staging = fn.call(_staging)
	staging_changed.emit(_staging)


# Apply current Appearance by copying current staging
func apply():
	_current = _staging.duplicate(true)
	current_changed.emit(_current)
