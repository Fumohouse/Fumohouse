extends PanelContainer

const SECTION_SCENE := preload(
	"res://addons/@fumohouse/fumo/character_editor/character_editor_custom_section.tscn"
)

var sorted_parts: Array[PartData]

@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _sections: Container = %Sections

@onready var _scopes: OptionButton = %Scopes


func _ready():
	scan_parts()

	# no way to read from export_enum annotations? to read from PartData.scope (lowercase property)
	for i in range(1, PartData.Scope.size()):
		_scopes.add_item(PartData.Scope.keys()[i], PartData.Scope.values()[i])


func scan_parts():
	sorted_parts = _part_database.parts.values().duplicate(true)

	sorted_parts.sort_custom(
		func(a: PartData, b: PartData) -> bool:
			return a.scope < b.scope && a.display_name < b.display_name
	)

	var section: CharacterEditorCustomSection

	for part in sorted_parts:
		var scope = part.Scope.keys()[part.scope]

		if not section or section.scope != scope:
			section = SECTION_SCENE.instantiate()
			section.scope = scope
			_sections.add_child(section)

		section.add_item(part)
