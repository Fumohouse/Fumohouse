extends PanelContainer

const PartSelector := preload("res://addons/@fumohouse/fumo/character_editor/part_selector.gd")
const _SELECTOR_SCENE := preload("res://addons/@fumohouse/fumo/character_editor/part_selector.tscn")

@onready var _part_selectors: Container = %PartSelectors
@onready var _scopes: OptionButton = %Scopes


func _ready():
	_scan_parts()
	_setup_scopes()


func _scan_parts():
	for child in _part_selectors.get_children():
		child.queue_free()

	for scope in PartData.Scope.values().slice(1):
		var part_selector: PartSelector = _SELECTOR_SCENE.instantiate()
		part_selector.scope = scope
		_part_selectors.add_child(part_selector)


func _setup_scopes():
	_scopes.add_item("All", 0)

	for scope: PartData.Scope in PartData.Scope.values().slice(1):
		# TODO: can't seem to read human-readable names from @export_enum
		_scopes.add_item(PartData.Scope.keys()[scope])
		_scopes.set_item_metadata(_scopes.item_count - 1, scope)

	_scopes.item_selected.connect(_filter_section)


func _filter_section(index: int):
	var scope: Variant = _scopes.get_item_metadata(index)

	for section: PartSelector in _part_selectors.get_children():
		section.visible = scope == null or section.scope == scope
		section.show_title(scope == null)
