class_name ConfigManager
extends Node
## A dynamic, persistent configuration manager.
##
## Define options in [method _enter_tree]. Option values should be available in
## [method _ready].

## Emitted when a config value changes.
signal value_changed(key: StringName)

## Emitted when a configuration option that requires a restart changes.
signal restart_required

var CONFIG_LOCATION := "user://config.ini"
var AUTOSAVE_TIMEOUT := 30.0

var _config := ConfigFile.new()
# Dedicated to prevent ProjectSettings.save_custom from causing outdated
# settings.
var _override_config := ConfigFile.new()
var _autosave_timeout := 0.0
var _options: Dictionary[StringName, ConfigOption] = {}


static func get_singleton() -> ConfigManager:
	return Modules.get_singleton(&"ConfigManager") as ConfigManager


func _ready():
	load_file()
	QuitManager.get_singleton().before_quit.connect(_on_before_quit)


func _process(delta: float):
	if _autosave_timeout <= 0.0:
		return

	_autosave_timeout = move_toward(_autosave_timeout, 0.0, delta)
	if _autosave_timeout == 0.0:
		save_file()


## Check if the internal config has an option defined.
func has_opt(key: StringName):
	var split := _split_key(key)
	return _config.has_section_key(split[0], split[1])


## Get the value of an option.
func get_opt(key: StringName) -> Variant:
	var split := _split_key(key)
	return _config.get_value(split[0], split[1])


## Get the default value of an option.
func get_default(key: StringName) -> Variant:
	return _options[key].default


## Get the required [OS] features for an option.
func get_opt_features(key: StringName):
	return _options[key].features


## Add a config option.
func add_opt(
		key: StringName,
		default: Variant,
		handler := func(value: Variant): pass,
		restart_required := false,
		features: PackedStringArray = [],
		obj_class_override: StringName = "",
):
	if _options.has(key):
		push_error("[ConfigManager] Option already exists: '%s'" % key)
		return

	var opt := ConfigOption.new()
	opt.type = typeof(default)
	if opt.type == TYPE_OBJECT:
		if obj_class_override.is_empty():
			opt.obj_class = (default as Object).get_class()
		else:
			opt.obj_class = obj_class_override

	opt.default = default
	opt.handler = handler
	opt.restart_required = restart_required
	opt.features = features

	_options[key] = opt


## Set the value of an option.
func set_opt(key: StringName, value: Variant, is_init := false):
	if has_opt(key) and get_opt(key) == value:
		return

	var opt := _options[key]
	if not opt.type_matches(value):
		push_error("[ConfigManager] Config value %s is the wrong type (got %d, expected %d)" %
				[key, typeof(value), opt.type])
		return

	var split := _split_key(key)
	_config.set_value(split[0], split[1], value)

	opt.handler.call(value)
	value_changed.emit(key)
	if not is_init and opt.restart_required:
		restart_required.emit()

	_autosave_timeout = AUTOSAVE_TIMEOUT


## Set a [ProjectSettings] override option.
func set_project_settings_opt(key: StringName, value: Variant):
	var split := _split_key(key)
	_override_config.set_value(split[0], split[1], value)


## Load configuration from file.
func load_file():
	print("[ConfigManager] Loading from file...")
	var err = _config.load(CONFIG_LOCATION)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("[ConfigManager] Failed to load config file at %s (error %d)." %
				[CONFIG_LOCATION, err])

	# Initialize values
	for key in _options:
		var opt := _options[key]
		if has_opt(key):
			var val: Variant = get_opt(key)
			if opt.type_matches(val):
				opt.handler.call_deferred(val) # defer e.g. due to UI scale
				continue

		# Fall back to default value if current one is missing or invalid.
		# This will also call the handler automatically.
		set_opt(key, opt.default, true)


## Save configuration to file.
func save_file():
	print("[ConfigManager] Saving...")
	var err := _config.save(CONFIG_LOCATION)
	if err == OK:
		_autosave_timeout = 0.0
	else:
		push_error("[ConfigManager] Failed to save config file to %s (error %d)." %
				[CONFIG_LOCATION, err])

	var override_path := ProjectSettings.get("application/config/project_settings_override") as String
	err = _override_config.save(override_path)
	if err != OK:
		push_error("[ConfigManager] Failed to save project settings override file to %s (error %d)." %
				[override_path, err])


func _split_key(key: StringName) -> Array[StringName]:
	var head := key.get_slice("/", 0)
	var tail := key.substr(head.length() + 1)
	return [head, tail]


func _on_before_quit():
	if _autosave_timeout > 0.0:
		save_file()


class ConfigOption extends RefCounted:
	var type: Variant.Type
	var obj_class := ""
	var default: Variant = null
	var handler: Callable = func(value: Variant): pass
	var restart_required := false
	var features: PackedStringArray = []

	func type_matches(value: Variant):
		if type == TYPE_OBJECT:
			return (
					value is Object and (
							obj_class.is_empty() or
							(value as Object).is_class(obj_class))
			)

		return typeof(value) == type
