extends "./config_bound_control.gd"
## An [OptionButton] bound to [ConfigManager].

@onready var btn := input as OptionButton


func _ready():
	super()
	btn.item_selected.connect(_on_item_selected)


func _set_value(value: Variant):
	btn.select(value)


func _get_value():
	return btn.get_selected_id()


func _on_item_selected(idx: int):
	update_config_value()
