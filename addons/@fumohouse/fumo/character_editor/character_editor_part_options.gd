extends Control

const PartOptionsEditor := preload("components/part_options_editor.gd")
const _EDITOR_SCENE := preload("components/part_options_editor.tscn")

var _editors: Dictionary[StringName, PartOptionsEditor] = {}

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _editor_container: Control = %EditorContainer


func _ready():
	_update_editors()
	_fumo_appearances.staging_changed.connect(_update_editors)


func _update_editors():
	for part_id in _fumo_appearances.staging.attached_parts:
		if part_id in _editors:
			continue

		var part: PartData = _part_database.get_part(part_id)
		if not part or part.default_config.is_empty():
			continue

		var editor: PartOptionsEditor = _EDITOR_SCENE.instantiate()
		editor.part = part

		_editor_container.add_child(editor)
		_editors[part_id] = editor

	for part_id in _editors.duplicate():
		if part_id in _fumo_appearances.staging.attached_parts:
			continue

		_editors[part_id].queue_free()
		_editors.erase(part_id)
