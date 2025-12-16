extends Node

const _MAIN_MODULE := "@fumohouse/main"


func _ready():
	var mod: ModuleManifest = Modules.get_module(_MAIN_MODULE)
	if not mod:
		push_error("Could not find main module %s." % [_MAIN_MODULE])
		return

	Modules.prepare_module(_MAIN_MODULE)
	(func(): get_tree().change_scene_to_file(mod.entry_scene)).call_deferred()
