extends PanelContainer

const SECTION_SCENE := preload("res://addons/@fumohouse/fumo/character_editor/part_selector.tscn")

@onready var _part_selectors: Container = %PartSelectors
@onready var _scopes: OptionButton = %Scopes


func _ready():
	scan_parts()

	_scopes.add_item("All", 0)
	# no way to read from export_enum annotations? to read from PartData.scope (lowercase property)
	for part_data in PartData.Scope.keys().slice(1):
		var value: int = PartData.Scope[part_data]
		_scopes.add_item(part_data, value)
		_scopes.set_item_metadata(value, part_data)

	_scopes.item_selected.connect(_filter_section)


func scan_parts():
	for child in _part_selectors.get_children():
		child.queue_free()

	for scope in PartData.Scope.values():
		var part_selector = SECTION_SCENE.instantiate()
		part_selector.scope = scope
		_part_selectors.add_child(part_selector)


func _filter_section(index: int):
	var scope: Variant = _scopes.get_item_metadata(index)

	for section: CharacterEditorCustomSection in _part_selectors.get_children():
		section.visible = not scope or section.scope == scope
		section.show_title(scope == null)
