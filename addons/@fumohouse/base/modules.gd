extends Node
## A singleton for managing modules.

const LOG_SCOPE := "Modules"

const _MODULES_DIR := "res://addons/"
const _MANIFEST_NAME := "module.tres"

var _modules: Dictionary[StringName, ModuleManifest] = {}
var _autoloads: Dictionary[StringName, Object] = {}


func _enter_tree():
	if not OS.is_debug_build():
		_mount_paks(OS.get_executable_path().get_base_dir().path_join("modules"))

	_scan_modules()

	# This step must run before _ready of the main scene, otherwise everything
	# will explode
	var scene_path: String = get_tree().current_scene.scene_file_path
	var scene_path_split: PackedStringArray = scene_path.trim_prefix(_MODULES_DIR).split("/")
	var scene_module: String = "/".join(scene_path_split.slice(0, 2))
	Log.info("Detected main scene in module '%s'!" % scene_module, LOG_SCOPE)

	prepare_module(scene_module)


## Get the singleton instance given by [param name].
func get_singleton(name: StringName) -> Object:
	return _autoloads.get(name)


## Get the list of currently detected modules.
func get_modules() -> Array[ModuleManifest]:
	return _modules.values()


## Get the module with the given [param name], or [code]null[/code] if it is not
## present.
func get_module(name: StringName) -> ModuleManifest:
	return _modules.get(name)


## Returns a topological ordering of the dependency graph starting from
## [param from]. Includes any [member ModuleManifest.auto_load] modules
## and their dependencies at the end of the list.
func walk_dependencies(from: StringName) -> Array[StringName]:
	var out: Array[StringName] = ["@fumohouse/base"]
	_walk_dependencies_internal(from, out)

	for module_name in _modules:
		if _modules[module_name].always_load:
			_walk_dependencies_internal(module_name, out)

	return out


## Prepare the main scene of the given [param module] to be run (e.g., load
## dependent autoloads).
func prepare_module(module: StringName):
	var ordering: Array[StringName] = walk_dependencies(module)
	Log.info("Determined module load order: %s" % " -> ".join(ordering), LOG_SCOPE)
	_load_autoloads(ordering)


func _index_module(path: String):
	var manifest := load(path.path_join(_MANIFEST_NAME)) as ModuleManifest
	if not manifest:
		Log.error("Invalid manifest at '%s'." % path, LOG_SCOPE)
		return

	var cfg := ConfigFile.new()
	var err: Error = cfg.load(path.path_join("plugin.cfg"))
	if err != OK:
		Log.error("Failed to load plugin configuration for '%s'." % path, LOG_SCOPE)
		return

	manifest.name = cfg.get_value("plugin", "name", "")
	manifest.description = cfg.get_value("plugin", "description", "")
	manifest.author = cfg.get_value("plugin", "author", "")
	manifest.version = cfg.get_value("plugin", "version", "")

	var module_name := StringName(path.substr(_MODULES_DIR.length()))

	if module_name == &"@fumohouse/base":
		var copyright := CopyrightFile.new()
		if copyright.parse("res://COPYRIGHT.txt"):
			manifest.copyright = copyright
	else:
		var copyright_path := path.path_join("COPYRIGHT.txt")
		if FileAccess.file_exists(copyright_path):
			var copyright := CopyrightFile.new()
			if copyright.parse(path.path_join("COPYRIGHT.txt")):
				manifest.copyright = copyright

	_modules[module_name] = manifest
	Log.debug("Indexed module '%s'." % module_name, LOG_SCOPE)


func _scan_modules():
	Log.info("Scanning for modules...", LOG_SCOPE)

	var mods_dir := DirAccess.open(_MODULES_DIR)
	if not mods_dir:
		Log.error("Failed to open modules directory.", LOG_SCOPE)
		return

	mods_dir.list_dir_begin()
	var mod_file: String = mods_dir.get_next()

	while not mod_file.is_empty():
		if not mods_dir.current_is_dir() or not mod_file.begins_with("@"):
			mod_file = mods_dir.get_next()
			continue

		var scope_path: String = _MODULES_DIR.path_join(mod_file)
		var scope_dir := DirAccess.open(scope_path)
		if not scope_dir:
			Log.error("Failed to open scope directory '%s'." % mod_file, LOG_SCOPE)
			continue

		scope_dir.list_dir_begin()
		var scope_file: String = scope_dir.get_next()

		while scope_file != "":
			if not scope_dir.current_is_dir():
				scope_file = scope_dir.get_next()
				continue

			_index_module(scope_path.path_join(scope_file))

			scope_file = scope_dir.get_next()

		mod_file = mods_dir.get_next()


func _mount_paks(path: String):
	var dir := DirAccess.open(path)
	if not dir:
		Log.error("Failed to read directory: %s." % [path], LOG_SCOPE)
		return

	dir.list_dir_begin()

	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var full_path := path.path_join(file_name)

		if dir.current_is_dir():
			_mount_paks(full_path)
		elif file_name.ends_with(".pck"):
			Log.info("Loading PCK %s..." % [full_path], LOG_SCOPE)
			if not ProjectSettings.load_resource_pack(full_path, false):
				Log.error("Failed to load PCK.", LOG_SCOPE)
				return

		file_name = dir.get_next()


func _walk_dependencies_internal(from: StringName, out: Array[StringName]):
	var manifest := _modules[from]
	for dep in manifest.dependencies:
		if out.has(dep.name):
			continue
		_walk_dependencies_internal(dep.name, out)

	out.push_back(from)


## Loads the autoloads of the modules in the given [param ordering] (which
## should be found by [method _walk_dependencies]).
func _load_autoloads(ordering: Array[StringName]):
	Log.info("Loading autoloads...", LOG_SCOPE)
	for mod in ordering:
		var manifest := _modules[mod]
		for autoload in manifest.autoloads:
			if _autoloads.has(autoload.name):
				continue

			var res: Resource = load(autoload.path)
			if res is GDScript:
				var obj: Object = (res as GDScript).new()
				if obj is Node:
					obj.name = autoload.name
					add_child(obj as Node)
				_autoloads[autoload.name] = obj
				Log.info("Loaded autoload class '%s'." % autoload.name, LOG_SCOPE)
			elif res is PackedScene:
				var node: Node = (res as PackedScene).instantiate()
				add_child(node)
				_autoloads[autoload.name] = node
				Log.info("Loaded autoload scene '%s'." % autoload.name, LOG_SCOPE)
