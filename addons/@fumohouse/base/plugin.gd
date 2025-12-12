@tool
extends EditorPlugin

const _DOCK_SCENE := preload("./editor/dock.tscn")

var _dock: Control


func _enter_tree():
	_dock = _DOCK_SCENE.instantiate() as Control
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree():
	remove_control_from_docks(_dock)
	_dock.free()
