extends Node
## A singleton for managing modules.

const _MODULES_DIR := "res://addons/"
const _MANIFEST_NAME := "module.tres"

var _modules: Dictionary[StringName, ModuleManifest] = {}
var _configs: Dictionary[StringName, ConfigFile] = {}
var _autoloads: Dictionary[StringName, Object] = {}


func _enter_tree():
	_scan_modules()

	# This step must run before _ready of the main scene, otherwise everything
	# will explode
	var scene_path: String = get_tree().current_scene.scene_file_path
	var scene_path_split: PackedStringArray = \
			scene_path.substr(_MODULES_DIR.length()).split("/")
	var scene_module: String = "/".join(scene_path_split.slice(0, 2))
	print("[Modules] Detected main scene in module '%s'!" % scene_module)

	var ordering: Array[StringName] = _walk_dependencies(scene_module)
	print("[Modules] Determined module load order: %s" % " -> ".join(ordering))
	_load_autoloads(ordering)


## Get the singleton instance given by [param name].
func get_singleton(name: StringName) -> Object:
	return _autoloads[name]


func _index_module(path: String):
	var manifest := load(path.path_join(_MANIFEST_NAME)) as ModuleManifest
	if not manifest:
		push_error("[Modules] Invalid manifest at '%s'." % path)
		return

	var cfg := ConfigFile.new()
	var err: Error = cfg.load(path.path_join("plugin.cfg"))
	if err != OK:
		push_error("[Modules] Failed to load plugin configuration for '%s'." % path)
		return

	var module_name := StringName(path.substr(_MODULES_DIR.length()))
	_modules[module_name] = manifest
	_configs[module_name] = cfg
	print("[Modules] Indexed module '%s'." % module_name)


func _scan_modules():
	print("[Modules] Scanning for modules...")

	var mods_dir := DirAccess.open(_MODULES_DIR)
	if not mods_dir:
		push_error("[Modules] Failed to open modules directory.")
		return

	mods_dir.list_dir_begin()
	var mod_file: String = mods_dir.get_next()

	while mod_file != "":
		if not mods_dir.current_is_dir() or not mod_file.begins_with("@"):
			mod_file = mods_dir.get_next()
			continue

		var scope_path: String = _MODULES_DIR.path_join(mod_file)
		var scope_dir := DirAccess.open(scope_path)
		if not scope_dir:
			push_error("[Modules] Failed to open scope directory '%s'." % mod_file)
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


func _walk_dependencies_internal(from: StringName, out: Array[StringName]):
	var manifest := _modules[from]
	for dep in manifest.dependencies:
		if out.has(dep.name):
			continue
		_walk_dependencies_internal(dep.name, out)

	out.push_back(from)


## Returns a topological ordering of the dependency graph starting from
## [param from].
func _walk_dependencies(from: StringName) -> Array[StringName]:
	var out: Array[StringName] = ["@fumohouse/base"]
	_walk_dependencies_internal(from, out)
	return out


## Loads the autoloads of the modules in the given [param ordering] (which
## should be found by [method _walk_dependencies]).
func _load_autoloads(ordering: Array[StringName]):
	print("[Modules] Loading autoloads...")
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
				print("[Modules] Loaded autoload class '%s'." % autoload.name)
			elif res is PackedScene:
				var node: Node = (res as PackedScene).instantiate()
				add_child(node)
				_autoloads[autoload.name] = node
				print("[Modules] Loaded autoload scene '%s'." % autoload.name)
