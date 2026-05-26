extends "res://addons/@fumohouse/config/ui/config_option_button.gd"


func _ready():
	super()
	_update_label()


func _on_config_value_changed(key: StringName):
	if key == &"graphics/vsync_mode":
		_update_label()

	super(key)


func _update_label():
	var vsync_mode: DisplayServer.VSyncMode = config_manager.get_opt(&"graphics/vsync_mode")
	btn.set_item_text(0, "VSync" if vsync_mode != DisplayServer.VSYNC_DISABLED else "Unlimited")
