@tool
extends Control

const ModuleExporter := preload("module_exporter.gd")

var _selected_modules: PackedStringArray = []

@onready var _refresh_button: Button = %Refresh
@onready var _module_list: Control = %ModuleList
@onready var _platform: OptionButton = %Platform
@onready var _export_path: LineEdit = %ExportPath
@onready var _export_modules_btn: Button = %ExportModules


func _ready():
	_refresh_button.pressed.connect(_refresh)
	_export_modules_btn.pressed.connect(_on_export_modules_pressed)


func _refresh():
	for node in _module_list.get_children():
		node.queue_free()
	_selected_modules.clear()

	var mods_dir := DirAccess.open("res://addons")
	if not mods_dir:
		push_error("Failed to open modules directory.")
		return

	mods_dir.list_dir_begin()
	var mod_file: String = mods_dir.get_next()

	while not mod_file.is_empty():
		if not mods_dir.current_is_dir() or not mod_file.begins_with("@"):
			mod_file = mods_dir.get_next()
			continue

		var scope_path: String = "res://addons".path_join(mod_file)
		var scope_dir := DirAccess.open(scope_path)
		if not scope_dir:
			push_error("Failed to open scope directory '%s'." % mod_file)
			continue

		scope_dir.list_dir_begin()
		var scope_file: String = scope_dir.get_next()

		while scope_file != "":
			if not scope_dir.current_is_dir():
				scope_file = scope_dir.get_next()
				continue

			var module_name := mod_file.path_join(scope_file)
			if module_name != "@fumohouse/base":
				var checkbox := CheckBox.new()
				checkbox.button_pressed = true
				checkbox.text = module_name
				checkbox.toggled.connect(
					func(toggled: bool):
						if toggled:
							_selected_modules.push_back(module_name)
						else:
							_selected_modules.erase(module_name)
				)
				_module_list.add_child(checkbox)

				_selected_modules.push_back(module_name)

			scope_file = scope_dir.get_next()

		mod_file = mods_dir.get_next()


func _on_export_modules_pressed():
	if _export_path.text.is_empty():
		return

	ModuleExporter.export(
		_selected_modules, _platform.get_item_text(_platform.selected), _export_path.text
	)
