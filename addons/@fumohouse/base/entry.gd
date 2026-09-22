extends Node

const Updater := preload("utils/updater.gd")
const LOG_SCOPE := "Entry"
const _MAIN_MODULE := "@fumohouse/main"

@onready var _updater: Updater = %Updater


func _ready():
	if not OS.is_debug_build() and _updater.is_supported:
		var success := await _updater.start()
		if success:
			_start_main()
	else:
		_start_main()


func _start_main():
	Modules.mount_paks()
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
