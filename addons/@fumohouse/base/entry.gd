extends Node

const Updater := preload("utils/updater.gd")
const LOG_SCOPE := "Entry"
const _MAIN_MODULE := "@fumohouse/main"

var _got_version := false
var _module_complete_count := 0
var _module_count := 0
var _can_continue := true

@onready var _updater: Updater = %Updater
@onready var _message: Label = %Message
@onready var _version: Label = %Version
@onready var _continue: Button = %Continue


func _ready():
	_continue.pressed.connect(_start_main)

	var is_debug := OS.is_debug_build()
	var exec_dir: String = BaseUtils.get_exec_dir()

	var override_modules_path: String = exec_dir.path_join("modules")
	var disable_updater_path_1: String = exec_dir.path_join("disable_updates")
	var disable_updater_path_2 := "user://disable_updates"

	if not is_debug and DirAccess.dir_exists_absolute(override_modules_path):
		(
			Log
			. info(
				"Detected modules directory adjacent to Fumohouse. Skipping updater and using these modules instead...",
				LOG_SCOPE
			)
		)
		_start_main(override_modules_path)
	elif (
		not is_debug
		and (
			FileAccess.file_exists(disable_updater_path_1)
			or FileAccess.file_exists(disable_updater_path_2)
		)
	):
		Log.info("Updater disabled by disable_updates file. Starting...", LOG_SCOPE)
		_start_main()
	elif not is_debug and _updater.is_supported:
		_message.text = "Checking for updates…"
		_updater.got_version.connect(
			func(version: String, version_name: String):
				_version.text = "Current version: %s" % version_name
				_can_continue = false
				_got_version = true
		)
		_updater.bp_validated.connect(
			func(success: bool):
				if not success:
					_message.text = "The base package is out-of-date.\nPlease update the base package for modules to be updated."
					_can_continue = true
		)
		_updater.got_downloads.connect(
			func(modules: PackedStringArray):
				if modules.is_empty():
					_message.text = "Everything is up-to-date. Starting…"
				else:
					_module_count = modules.size()
					_message.text = "Updating %d modules…" % [_module_count]
		)
		_updater.download_complete.connect(
			func(mod: String, success: bool):
				if not success:
					_message.text = "Failed to download %s. See logs for details." % mod
		)
		_updater.extract_complete.connect(
			func(mod: String, success: bool):
				if success:
					_module_complete_count += 1
					_message.text = (
						"Updating modules (%d/%d)…" % [_module_complete_count, _module_count]
					)
				else:
					_message.text = "Failed to extract %s. See logs for details." % mod
		)

		var success := await _updater.start()
		if success:
			# Refresh text display
			for i in 2:
				await get_tree().process_frame
			_start_main()
		elif _can_continue:
			if DisplayServer.get_name() == "headless":
				Log.info("Updater failed. Starting server anyway...", LOG_SCOPE)
				_start_main()
			else:
				if not _got_version:
					_message.text = "Failed to get latest version. Are you online?"
				_continue.show()
	else:
		_start_main()


func _start_main(pak_path := Modules.PAK_DIR):
	if not OS.is_debug_build():
		Modules.mount_paks(pak_path)
	Modules.scan_modules()

	var mod: ModuleManifest = Modules.get_module(_MAIN_MODULE)
	if not mod:
		Log.error("Could not find main module %s." % [_MAIN_MODULE], LOG_SCOPE)
		return

	Modules.prepare_module(_MAIN_MODULE)

	if DisplayServer.get_name() == "headless":
		Log.info("Headless mode detected. Using CLI...", LOG_SCOPE)
		var script: GDScript = load(mod.entry_script)
		var script_node: Node = script.new()
		# Don't set it as the scene, so that CLI state can persist if a world is loaded
		get_tree().root.add_child.call_deferred(script_node)
	else:
		(func(): get_tree().change_scene_to_file(mod.entry_scene)).call_deferred()
