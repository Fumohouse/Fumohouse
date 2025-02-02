extends Control
## A [Control] that edits a [ConfigManager] option.
##
## This option is automatically hidden if the required [OS] features are not
## present.

## The [Control] that the user interacts with to change the option.
@export var input: Control

## The [Button] that revers the option to default when clicked. Automatically
## hidden when the option has the default value.
@export var revert_button: Button

## The key of the option.
@export var key := &""

var _updating_config := false

@onready var config_manager := ConfigManager.get_singleton()


func _ready():
	for feature in config_manager.get_opt_features(key):
		if not OS.has_feature(feature):
			visible = false
			return

	_update_from_config.call_deferred()

	if revert_button:
		revert_button.pressed.connect(_on_revert_button_pressed)

	config_manager.value_changed.connect(_on_config_value_changed)


## Derived classes should call this when the [member input]'s value changes to
## update the [ConfigManager] entry.
func update_config_value():
	_updating_config = true
	config_manager.set_opt(key, _get_value())
	_updating_config = false


## Override to update the [member input]'s value.
func _set_value(value: Variant):
	pass


## Override to get the value from [member input].
func _get_value() -> Variant:
	return null


## Determine whether two values are approximately equal.
func _approx_equal(a: Variant, b: Variant):
	if a == b:
		return true

	if a is float and b is float:
		return absf(a - b) < 1e-4

	return false


func _update_from_config():
	var value: Variant = config_manager.get_opt(key)

	if revert_button:
		revert_button.visible = not _approx_equal(value,
				config_manager.get_default(key))

	if not _updating_config:
		_set_value(value)


func _on_revert_button_pressed():
	config_manager.set_opt(key, config_manager.get_default(key))


func _on_config_value_changed(key: StringName):
	if key != self.key:
		return

	_update_from_config()
