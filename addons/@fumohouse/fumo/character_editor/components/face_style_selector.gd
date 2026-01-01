extends Control

const FacePreviewButton := preload("face_preview_button.gd")
const _BUTTON_SCENE := preload("face_preview_button.tscn")

@export_enum("Eyes", "Eyebrows", "Mouth") var part_type: int = 0

var _updating := false

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _title: Label = %Title
@onready var _grid: RadioButtonContainer = %Grid


func _ready():
	_grid.allow_none = true
	_grid.selection_changed.connect(_on_selection_changed)

	var list: Array
	if part_type == 0:
		_title.text = "Eyes"
		list = FumoAppearanceManager.FACE_DATABASE.eye_styles
	elif part_type == 1:
		_title.text = "Eyebrows"
		list = FumoAppearanceManager.FACE_DATABASE.eyebrow_styles
	elif part_type == 2:
		_title.text = "Mouth"
		list = FumoAppearanceManager.FACE_DATABASE.mouth_styles

	for style: Resource in list:
		var button: FacePreviewButton = _BUTTON_SCENE.instantiate()
		button.style = style
		_grid.add_child(button)

	_update_selection()
	_fumo_appearances.staging_changed.connect(_update_selection)


func _select_id(id: StringName):
	for button: FacePreviewButton in _grid.get_children():
		if button.id == id:
			_grid.selected_button = button


func _update_selection():
	var id: Variant
	if part_type == 0:
		id = _fumo_appearances.staging.config.get(&"eyes")
	elif part_type == 1:
		id = _fumo_appearances.staging.config.get(&"eyebrows")
	elif part_type == 2:
		id = _fumo_appearances.staging.config.get(&"mouth")

	_updating = true
	if id:
		_select_id(id)
	else:
		_grid.selected_button = null
	_updating = false


func _on_selection_changed():
	if _updating:
		return

	var btn: FacePreviewButton = _grid.selected_button
	var id: Variant = btn.id if btn else null
	if part_type == 0:
		_fumo_appearances.staging.config[&"eyes"] = id
	elif part_type == 1:
		_fumo_appearances.staging.config[&"eyebrows"] = id
	elif part_type == 2:
		_fumo_appearances.staging.config[&"mouth"] = id

	_fumo_appearances.staging_changed.emit()
