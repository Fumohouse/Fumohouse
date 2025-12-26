extends "res://addons/@fumohouse/navigation/transition_element.gd"

const MusicController = preload("res://addons/@fumohouse/music/music_controller.gd")
const NavButtonContainer = preload(
	"res://addons/@fumohouse/navigation/components/nav_button_container.gd"
)
const NavCharacter := preload(
	"res://addons/@fumohouse/navigation/character_editor/nav_character.gd"
)

@onready var _gradient_background: Control = $GradientBackground
@onready var _title: Control = $Contents/Title
@onready var _nav_buttons: NavButtonContainer = $Contents/NavButtonContainer
@onready var _bottom_bar: Control = $BottomBar
@onready var _world_name: Label = %WorldName
@onready var _music_controller: MusicController = $MusicController
@onready var _nav_character: NavCharacter = $NavCharacter


func _ready():
	var current_world: WorldManifest = WorldManager.get_singleton().get_current_world()
	if not current_world:
		return
	_world_name.text = "%s • %s" % [current_world.display_name, current_world.author]


func nav_hide():
	_gradient_background.modulate = Color.TRANSPARENT
	_title.modulate = Color.TRANSPARENT
	_nav_buttons.nav_hide()
	_bottom_bar.modulate = Color.TRANSPARENT
	_bottom_bar.position.y = _bottom_bar_target_y(false)
	_music_controller.nav_hide()
	_nav_character.nav_hide()


func nav_show():
	_gradient_background.modulate = Color.WHITE
	_title.modulate = Color.WHITE
	_nav_buttons.nav_show()
	_bottom_bar.modulate = Color.WHITE
	_bottom_bar.position.y = _bottom_bar_target_y(true)
	_music_controller.nav_show()
	_nav_character.nav_show()


func nav_transition(vis: bool) -> Tween:
	var tween := MenuUtils.common_tween(self, vis)
	var target_modulate := Color.WHITE if vis else Color.TRANSPARENT

	tween.tween_property(
		_gradient_background, "modulate", target_modulate, MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		_title, "modulate", target_modulate, MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		_bottom_bar, "modulate", target_modulate, MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		_bottom_bar, "position:y", _bottom_bar_target_y(vis), MenuUtils.TRANSITION_DURATION
	)

	_nav_buttons.nav_transition(vis)
	_music_controller.nav_transition(vis)
	_nav_character.nav_transition(vis)

	return tween


func _bottom_bar_target_y(vis: bool):
	return size.y - _bottom_bar.size.y if vis else size.y
