extends "./config_option_button.gd"
## A special [OptionButton] used to configure audio output devices for
## [AudioConfigManager].

@onready var _devices: PackedStringArray = AudioServer.get_output_device_list()


func _ready():
	for device in _devices:
		btn.add_item(device)

	super._ready()


func _set_value(value: Variant):
	var idx := _devices.find(value)
	if idx >= 0:
		btn.select(idx)
	else:
		btn.add_item(value)
		btn.select(btn.item_count - 1)


func _get_value():
	return _devices[btn.selected]
