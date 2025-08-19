extends "../navigation/transition_element.gd"

const MusicController = preload("res://addons/@fumohouse/music/music_controller.gd")
const NavButtonContainer = preload("../navigation/components/nav_button_container.gd")

@onready var _non_navigation: Control = $NonNavigation
@onready var _main_buttons: NavButtonContainer = $MainButtons
@onready var _music_controller: MusicController = $MusicController

@onready var _top_bar: Control = $NonNavigation/TopBar
@onready var _version_label: Control = $NonNavigation/VersionLabel

@onready var _music_button: Button = %MusicButton


func _ready():
	_music_controller.nav_hide()
	_music_button.pressed.connect(_on_music_button_pressed)


func nav_hide():
	_non_navigation.modulate = Color.TRANSPARENT
	_main_buttons.nav_hide()
	_top_bar.position.y = _top_bar_target_y(false)
	_version_label.position.x = _version_label_target_x(false)


func nav_show():
	_non_navigation.modulate = Color.WHITE
	_main_buttons.nav_show()
	_top_bar.position.y = _top_bar_target_y(true)
	_version_label.position.x = _version_label_target_x(true)


func nav_transition(vis: bool):
	var tween := MenuUtils.common_tween(self, vis)
	var target_modulate := Color.WHITE if vis else Color.TRANSPARENT

	tween.parallel().tween_property(
		_non_navigation, "modulate", target_modulate, MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		_top_bar, "position:y", _top_bar_target_y(vis), MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		_version_label, "position:x", _version_label_target_x(vis), MenuUtils.TRANSITION_DURATION
	)

	_main_buttons.nav_transition(vis)

	return tween


func _on_music_button_pressed():
	_music_controller.nav_transition(not _music_controller.visible)


func _top_bar_target_y(vis: bool):
	return 0 if vis else -_top_bar.size.y - MenuUtils.MARGIN


func _version_label_target_x(vis: bool):
	if vis:
		return _non_navigation.size.x - _version_label.size.x
	else:
		return _non_navigation.size.x + MenuUtils.MARGIN
