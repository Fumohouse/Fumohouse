extends "res://addons/@fumohouse/navigation/nav_menu.gd"

## Other nodes (e.g., [CameraController]) respond to menu opening.
signal opened

const NavCharacter := preload(
	"res://addons/@fumohouse/navigation/character_editor/nav_character.gd"
)
const BLUR_PARAM := "shader_parameter/blur"
const DIM_PARAM := "shader_parameter/dim"

var _is_visible := false
var _is_leaving := false
var _old_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_MAX
var _tween: Tween

@onready var _continue_button: Button = %ContinueButton
@onready var _info_button: Button = %InfoButton
@onready var _options_button: Button = %OptionsButton
@onready var _leave_button: Button = %LeaveButton

@onready var _nav_character: NavCharacter = %NavCharacter

@onready var _main_screen: TransitionElement = $Screens/MenuScreen
@onready var _info_screen: TransitionElement = $Screens/InfoScreenWorld
@onready var _options_screen: TransitionElement = $Screens/OptionsScreen
@onready var _leave_screen: TransitionElement = $Screens/LeaveScreen
@onready var _char_edit_screen: TransitionElement = $Screens/CharacterEditorScreen

@onready var _blur_background: Control = $Blur
@onready var _blur_mat: ShaderMaterial = _blur_background.material


func _ready():
	super()

	_continue_button.pressed.connect(func(): nav_transition(false))
	_info_button.pressed.connect(switch_screen.bind(_info_screen))
	_options_button.pressed.connect(switch_screen.bind(_options_screen))
	_leave_button.pressed.connect(_on_leave_button_pressed)

	_nav_character.edit_pressed.connect(switch_screen.bind(_char_edit_screen))

	nav_hide()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed(&"menu_back") and not _is_visible:
		nav_transition(true)
		get_viewport().set_input_as_handled()
		return

	super(event)


func nav_hide():
	super()

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur_background.visible = false

	# Godot dislikes tweening from 0 very much
	_blur_mat.set_shader_parameter(BLUR_PARAM, 0.001)
	_blur_mat.set_shader_parameter(DIM_PARAM, 0.001)

	_is_visible = false


func nav_transition(vis: bool) -> Tween:
	if vis:
		# Happens before input mode update due to things like CameraController
		# (hold right click to move camera).
		opened.emit()

		if _old_mouse_mode == Input.MOUSE_MODE_MAX:
			_old_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if _old_mouse_mode != Input.MOUSE_MODE_MAX:
			Input.mouse_mode = _old_mouse_mode
			_old_mouse_mode = Input.MOUSE_MODE_MAX

		var focus_owner: Control = get_viewport().gui_get_focus_owner()
		if focus_owner and (self == focus_owner or is_ancestor_of(focus_owner)):
			focus_owner.release_focus()

	if _tween:
		_tween.kill()

	mouse_filter = Control.MOUSE_FILTER_STOP if vis else Control.MOUSE_FILTER_IGNORE
	_blur_background.visible = true
	switch_screen(_main_screen if vis else null)

	var tween := MenuUtils.common_tween(self, vis)
	tween.tween_property(_blur_mat, BLUR_PARAM, 1.0 if vis else 0.0, MenuUtils.TRANSITION_DURATION)
	tween.parallel().tween_property(
		_blur_mat, DIM_PARAM, 0.3 if vis else 0.0, MenuUtils.TRANSITION_DURATION
	)
	_tween = tween
	_is_visible = vis

	if not vis:
		await tween.finished
		_blur_background.visible = false

	return tween


func dismiss():
	if not _continue_button.disabled:
		nav_transition(false)


func switch_screen(screen: TransitionElement):
	if screen == _main_screen:
		grab_focus()

	super(screen)


func _on_leave_button_pressed():
	_is_leaving = true
	inhibit_back = true
	switch_screen(_leave_screen)
	await get_tree().create_timer(0.5).timeout
	WorldManager.get_singleton().leave()
