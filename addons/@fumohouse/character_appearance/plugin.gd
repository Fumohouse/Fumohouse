@tool
extends EditorPlugin

const Dock := preload("./editor/dock.gd")
const DOCK_SCENE := preload("./editor/dock.tscn")

var dock: Dock


func _enter_tree():
	dock = DOCK_SCENE.instantiate() as Dock
	dock.plugin = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
