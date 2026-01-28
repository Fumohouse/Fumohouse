@tool
extends Control

const ModuleExporter := preload("module_exporter.gd")

var _selected_modules: PackedStringArray = []

@onready var _refresh_button: Button = %Refresh
@onready var _module_list: Control = %ModuleList
@onready var _platform: OptionButton = %Platform
@onready var _export_path: LineEdit = %ExportPath
@onready var _export_modules_btn: Button = %ExportModules
@onready var _export_base_btn: Button = %ExportBase


func _ready():
	_refresh_button.pressed.connect(_refresh)
	_export_modules_btn.pressed.connect(_on_export_modules_pressed)
	_export_base_btn.pressed.connect(_on_export_base_pressed)


func _refresh():
	for node in _module_list.get_children():
		node.queue_free()
	_selected_modules.clear()

	Modules.scan_modules()
	for module in Modules.get_modules():
		if module.name == "@fumohouse/base":
			continue

		var checkbox := CheckBox.new()
		checkbox.button_pressed = true
		checkbox.text = module.name
		checkbox.toggled.connect(
			func(toggled: bool):
				if toggled:
					_selected_modules.push_back(module.name)
				else:
					_selected_modules.erase(module.name)
		)
		_module_list.add_child(checkbox)

		_selected_modules.push_back(module.name)


func _on_export_modules_pressed():
	if _export_path.text.is_empty():
		return

	ModuleExporter.export(
		_selected_modules, _platform.get_item_text(_platform.selected), _export_path.text
	)


func _on_export_base_pressed():
	if _export_path.text.is_empty():
		return

	ModuleExporter.export_base_package(
		_platform.get_item_text(_platform.selected), _export_path.text
	)
