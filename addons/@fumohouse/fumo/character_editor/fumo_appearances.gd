class_name FumoAppearances
extends Node

signal current_changed(Appearance: Appearance)

signal staging_changed(Appearance: Appearance)

var _current: Appearance


static func get_singleton() -> FumoAppearances:
	return Modules.get_singleton(&"FumoAppearances") as FumoAppearances


# TODO: remove, kept for compatibility at the moment
func apply(appearance: Appearance):
	_current = appearance
	current_changed.emit(_current)
