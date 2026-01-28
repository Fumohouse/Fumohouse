@tool
extends Control

const LOG_SCOPE := "ModuleCreate"

@onready var _name_scope: LineEdit = %NameScope
@onready var _name_main: LineEdit = %NameMain
@onready var _description: TextEdit = %Description
@onready var _author: LineEdit = %Author
@onready var _version: LineEdit = %Version
@onready var _create_button: Button = %CreateButton


func _ready():
	_create_button.pressed.connect(_on_create_button_pressed)


func _on_create_button_pressed():
	var res: bool = _create_module(
		_name_scope.text, _name_main.text, _description.text, _author.text, _version.text
	)
	if res:
		_clear()


func _create_module(
	scope: String, name: String, description: String, author: String, version: String
) -> bool:
	if scope.is_empty() or name.is_empty():
		Log.error("Scope and name are required.", LOG_SCOPE)
		return false
	if author.is_empty():
		Log.error("Author is required.", LOG_SCOPE)
		return false

	var dir := "res://addons".path_join("@" + scope).path_join(name)
	if DirAccess.dir_exists_absolute(dir):
		Log.error("Module directory already exists.", LOG_SCOPE)
		return false

	var full_name := "@%s/%s" % [scope, name]

	DirAccess.make_dir_recursive_absolute(dir)

	(
		FileAccess
		. open(dir.path_join("plugin.gd"), FileAccess.WRITE)
		. store_string(
			"""@tool
extends EditorPlugin
"""
		)
	)

	var cfg := ConfigFile.new()
	cfg.set_value("plugin", "name", full_name)
	cfg.set_value("plugin", "description", description)
	cfg.set_value("plugin", "author", author)
	cfg.set_value("plugin", "version", version)
	cfg.set_value("plugin", "script", "plugin.gd")

	cfg.save(dir.path_join("plugin.cfg"))

	var manifest := ModuleManifest.new()
	ResourceSaver.save(manifest, dir.path_join("module.tres"))

	EditorInterface.set_plugin_enabled(full_name, true)
	return true


func _clear():
	_name_scope.clear()
	_name_main.clear()
	_description.clear()
	_version.clear()
