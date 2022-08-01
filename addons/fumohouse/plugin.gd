@tool
extends EditorPlugin


var dock: Control


func _enter_tree():
	dock = preload("dock.tscn").instantiate()
	dock.plugin = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
