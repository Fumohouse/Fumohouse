extends "./config_bound_control.gd"
## An [OptionButton] bound to [ConfigManager].

@onready var _btn := input as OptionButton


func _ready():
	super._ready()
	_btn.item_selected.connect(_on_item_selected)


func _set_value(value: Variant):
	_btn.select(value)


func _get_value():
	return _btn.get_selected_id()


func _on_item_selected(idx: int):
	update_config_value()
