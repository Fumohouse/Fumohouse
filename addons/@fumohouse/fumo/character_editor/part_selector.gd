extends Control

const PartPreviewButton := preload("part_preview_button.gd")
const _BUTTON_SCENE := preload("part_preview_button.tscn")

const DEFAULT_OUTFIT_FULL := &"doremy_outfit"
const DEFAULT_OUTFIT_TOP := &"momiji_outfit_top"
const DEFAULT_OUTFIT_BOTTOM := &"momiji_skirt"
const DEFAULT_HAIR_FULL := &"shanghai_hair"
const DEFAULT_HAIR_FRONT := &"doremy_hair_front"
const DEFAULT_HAIR_BACK := &"doremy_hair_back"

@export var scope: PartData.Scope

var _updating := false

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _grid: RadioButtonContainer = %Grid
@onready var _title: Label = %Title


func _ready():
	_title.text = PartData.SCOPE_NAMES[scope]

	_grid.multi_selection = (
		scope == PartData.Scope.ACCESSORY or scope == PartData.Scope.HAIR_ACCESSORY
	)
	_grid.selection_changed.connect(_on_selection_changed)

	for part in _part_database.parts.values():
		if part.scope != scope:
			continue

		var button: PartPreviewButton = _BUTTON_SCENE.instantiate()
		button.part = part
		button.tooltip_text = part.display_name
		_grid.add_child(button)

	_update_selection()
	_fumo_appearances.staging_changed.connect(_update_selection)


func show_title(vis: bool):
	_title.visible = vis


func _update_selection():
	var selection: Array[Button] = []

	for button: PartPreviewButton in _grid.get_children():
		if button.part.id in _fumo_appearances.staging.attached_parts:
			selection.push_back(button)

	_updating = true
	_grid.selected_buttons = selection
	_updating = false


func _on_selection_changed():
	if _updating:
		return

	var selection_ids: Array[StringName] = []
	for button: PartPreviewButton in _grid.selected_buttons:
		selection_ids.push_back(button.part.id)
		if not _fumo_appearances.staging.attached_parts.has(button.part.id):
			_fumo_appearances.staging.attached_parts[button.part.id] = null

	for part_id: StringName in _fumo_appearances.staging.attached_parts.keys():
		var part: PartData = _part_database.get_part(part_id)
		if not part or part.scope != scope:
			continue

		if not selection_ids.has(part_id):
			_fumo_appearances.staging.attached_parts.erase(part_id)

	_handle_exclusions()

	_fumo_appearances.staging_changed.emit()


func _any_attached_of_scope(search_scope: PartData.Scope) -> bool:
	for part_id: StringName in _fumo_appearances.staging.attached_parts.keys():
		var part: PartData = _part_database.get_part(part_id)
		if not part or part.scope != search_scope:
			continue

		return true

	return false


func _detach_parts_of_scopes(search_scopes: Array[PartData.Scope]):
	for part_id: StringName in _fumo_appearances.staging.attached_parts.keys():
		var part: PartData = _part_database.get_part(part_id)
		if not part or not search_scopes.has(part.scope):
			continue

		_fumo_appearances.staging.attached_parts.erase(part_id)


func _handle_exclusions():
	# this sucks but whatever
	var is_empty := _grid.selected_buttons.is_empty()
	if [PartData.Scope.OUTFIT_FULL, PartData.Scope.OUTFIT_TOP, PartData.Scope.OUTFIT_BOTTOM].has(
		scope
	):
		if (
			(
				is_empty
				and (scope == PartData.Scope.OUTFIT_TOP or scope == PartData.Scope.OUTFIT_BOTTOM)
			)
			or (not is_empty and scope == PartData.Scope.OUTFIT_FULL)
		):
			_detach_parts_of_scopes([PartData.Scope.OUTFIT_TOP, PartData.Scope.OUTFIT_BOTTOM])
			if not _any_attached_of_scope(PartData.Scope.OUTFIT_FULL):
				_fumo_appearances.staging.attached_parts[DEFAULT_OUTFIT_FULL] = null
		else:
			_detach_parts_of_scopes([PartData.Scope.OUTFIT_FULL])
			if not _any_attached_of_scope(PartData.Scope.OUTFIT_TOP):
				_fumo_appearances.staging.attached_parts[DEFAULT_OUTFIT_TOP] = null
			if not _any_attached_of_scope(PartData.Scope.OUTFIT_BOTTOM):
				_fumo_appearances.staging.attached_parts[DEFAULT_OUTFIT_BOTTOM] = null
	elif [PartData.Scope.HAIR_FULL, PartData.Scope.HAIR_FRONT, PartData.Scope.HAIR_BACK].has(scope):
		if (
			(is_empty and (scope == PartData.Scope.HAIR_FRONT or scope == PartData.Scope.HAIR_BACK))
			or (not is_empty and scope == PartData.Scope.HAIR_FULL)
		):
			_detach_parts_of_scopes([PartData.Scope.HAIR_FRONT, PartData.Scope.HAIR_BACK])
			if not _any_attached_of_scope(PartData.Scope.HAIR_FULL):
				_fumo_appearances.staging.attached_parts[DEFAULT_HAIR_FULL] = null
		else:
			_detach_parts_of_scopes([PartData.Scope.HAIR_FULL])
			if not _any_attached_of_scope(PartData.Scope.HAIR_FRONT):
				_fumo_appearances.staging.attached_parts[DEFAULT_HAIR_FRONT] = null
			if not _any_attached_of_scope(PartData.Scope.HAIR_BACK):
				_fumo_appearances.staging.attached_parts[DEFAULT_HAIR_BACK] = null
