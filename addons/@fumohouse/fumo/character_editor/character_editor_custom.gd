extends PanelContainer

const SECTION_SCENE := preload(
	"res://addons/@fumohouse/fumo/character_editor/character_editor_custom_section.tscn"
)

var scope_parts: Dictionary

@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _sections: Container = %Sections

@onready var _scopes: OptionButton = %Scopes


func _ready():
	scan_parts()

	# no way to read from export_enum annotations? to read from PartData.scope (lowercase property)
	for i in range(1, PartData.Scope.size()):
		_scopes.add_item(PartData.Scope.keys()[i], PartData.Scope.values()[i])


func scan_parts():
	for child in _sections.get_children():
		child.queue_free()

	scope_parts.clear()
	for part in _part_database.parts.values().duplicate():
		(scope_parts.get_or_add(part.Scope.keys()[part.scope], []) as Array).append(part)
	scope_parts.sort()

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
