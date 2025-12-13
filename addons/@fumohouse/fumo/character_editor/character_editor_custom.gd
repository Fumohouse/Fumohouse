extends PanelContainer

const SECTION_SCENE := preload(
	"res://addons/@fumohouse/fumo/character_editor/character_editor_custom_section.tscn"
)

var scope_parts: Dictionary[String, Array]

@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _sections: Container = %Sections

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


func _filter_section(index: int):
	var scope: Variant = _scopes.get_item_metadata(index)

	for section: CharacterEditorCustomSection in _sections.get_children():
		section.visible = not scope or section.scope == scope
		section.show_title(scope == null)


func scan_parts():
	for child in _sections.get_children():
		child.queue_free()

	scope_parts.clear()
	for key in PartData.Scope.keys():
		scope_parts[key] = []

	for part in _part_database.parts.values().duplicate():
		scope_parts.get(part.Scope.keys()[part.scope]).append(part)

	for scope in scope_parts.keys():
		var parts: Array = scope_parts[scope]
		if parts.is_empty():
			continue

		var section = SECTION_SCENE.instantiate()
		section.scope = scope
		_sections.add_child(section)

		parts.sort_custom(
			func(a: PartData, b: PartData) -> bool: return a.display_name < b.display_name
		)
		parts.map(section.add_part)
