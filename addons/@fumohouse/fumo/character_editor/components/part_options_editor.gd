extends Control

@export var part: PartData

var _editors: Dictionary[StringName, Control] = {}
var _updating := false

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _title: Label = %Title
@onready var _grid: Control = %Grid


func _ready():
	_title.text = part.display_name

	_init_options()
	_update_values()
	_fumo_appearances.staging_changed.connect(_update_values)


func _get_option(opt_name: StringName) -> Variant:
	var config: Variant = _fumo_appearances.staging.attached_parts.get(part.id)
	if config and opt_name in config:
		return config[opt_name]

	config = _fumo_appearances.part_config_cache.get(part.id)

	if config and opt_name in config:
		return config[opt_name]

	return part.default_config[opt_name]


func _set_option(opt_name: StringName, value: Variant):
	if _updating:
		return

	if part.id in _fumo_appearances.staging.attached_parts:
		if _fumo_appearances.staging.attached_parts[part.id] == null:
			_fumo_appearances.staging.attached_parts[part.id] = part.default_config

		_fumo_appearances.staging.attached_parts[part.id][opt_name] = value

	_fumo_appearances.staging_changed.emit()

	if part.id not in _fumo_appearances.part_config_cache:
		_fumo_appearances.part_config_cache[part.id] = part.default_config

	_fumo_appearances.part_config_cache[part.id][opt_name] = value


func _init_options():
	for opt_name in part.default_config:
		var editor_ctl: Control

		var val: Variant = part.default_config[opt_name]
		if val is Color:
			var picker := BasicColorPickerButton.new()
			picker.custom_minimum_size = Vector2(96, 32)
			picker.color_changed.connect(func(color: Color): _set_option(opt_name, color))

			editor_ctl = picker

		if editor_ctl:
			var lbl := Label.new()
			lbl.text = opt_name
			_grid.add_child(lbl)
			_grid.add_child(editor_ctl)

			_editors[opt_name] = editor_ctl


func _update_values():
	_updating = true

	for opt_name in _editors:
		var val: Variant = part.default_config[opt_name]
		if val is Color:
			var picker := _editors[opt_name] as BasicColorPickerButton
			picker.color = _get_option(opt_name)

	_updating = false
