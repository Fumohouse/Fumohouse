@tool
extends EditorPlugin

const _DOCK_SCENE := preload("./editor/dock.tscn")

var _dock: Control


func _enter_tree():
	var argv_in: PackedStringArray = OS.get_cmdline_user_args()
	var argd: Dictionary[StringName, String] = {}
	var argv: PackedStringArray = []
	ArgParse.parse(argv_in, argd, argv)
	if &"export" in argd:
		get_tree().quit(load("res://addons/@fumohouse/base/editor/export_cli.gd").run(argd, argv))
		return

	_dock = _DOCK_SCENE.instantiate() as Control
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree():
	if not _dock:
		return

	remove_control_from_docks(_dock)
	_dock.free()
