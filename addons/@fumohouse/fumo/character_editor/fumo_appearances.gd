class_name FumoAppearances
extends Node

signal active_changed(Appearance: Appearance)

signal staging_changed(Appearance: Appearance)

var _active: Appearance = preload(
	"res://addons/@fumohouse/fumo_models/resources/presets/doremy.tres"
)

var _staging: Appearance


static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


# Modify staging Appearance with [param fn], which takes staging as parameter and returns the modified value
func with_staging(fn: Callable):
	_staging = fn.call(_staging)
	staging_changed.emit(_staging)


# Apply active Appearance by copying from staging
func apply():
	_active = _staging.duplicate(true)
	active_changed.emit(_active)
