extends Control

const PartSelector := preload("components/part_selector.gd")
const _SELECTOR_SCENE := preload("components/part_selector.tscn")

@onready var _part_selectors: Container = %PartSelectors
@onready var _scopes: OptionButton = %Scopes


func _ready():
	for scope: PartData.Scope in PartData.Scope.values().slice(1):
		var part_selector: PartSelector = _SELECTOR_SCENE.instantiate()
		part_selector.scope = scope
		_part_selectors.add_child(part_selector)

		_scopes.add_item(PartData.SCOPE_NAMES[scope])
		_scopes.set_item_metadata(_scopes.item_count - 1, scope)

	_scopes.item_selected.connect(_filter_section)


func _filter_section(index: int):
	var scope: Variant = _scopes.get_item_metadata(index)

	for section: PartSelector in _part_selectors.get_children():
		section.visible = scope == null or section.scope == scope
		section.show_title(scope == null)
