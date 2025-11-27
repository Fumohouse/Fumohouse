extends Control

const MenuUtils := preload("menu_utils.gd")
const TransitionElement := preload("transition_element.gd")
const NavButton := preload("components/nav_button.gd")

@export var main_screen: TransitionElement

var inhibit_back := false

var _current_screen: TransitionElement  # also: _screen_in
var _tween_in: Tween
var _screen_out: TransitionElement
var _tween_out: Tween

@onready var _back_button: NavButton = $BackButton
@onready var _screens: Control = $Screens


func _ready():
	_back_button.visible = true  # hidden in editor
	_back_button.nav_hide()
	_back_button.pressed.connect(_on_back_button_pressed)

	for child in _screens.get_children():
		_hide_screen(child)


func _unhandled_input(event: InputEvent):
	if not inhibit_back and Input.is_action_pressed("menu_back"):
		var focus: Control = get_viewport().gui_get_focus_owner()
		if focus and focus.has_meta("block_dismiss") and focus.get_meta("block_dismiss") == true:
			return

		if _current_screen != main_screen:
			switch_screen(main_screen)
		else:
			dismiss()

		get_viewport().set_input_as_handled()


func nav_hide():
	if not _current_screen:
		return

	_hide_screen(_current_screen)
	_current_screen = null


func dismiss():
	pass


func switch_screen(screen: TransitionElement):
	if _current_screen == screen:
		return

	if _screen_out and _tween_out and _tween_in:
		# Prevent hiding when switching too quickly
		_hide_screen(_screen_out)
		_tween_out.kill()
		_tween_in.kill()

	_screen_out = _current_screen
	if _current_screen:
		_tween_out = _transition_screen(_current_screen, false)

	if screen:
		_tween_in = _transition_screen(screen, true)

	if not inhibit_back:
		_back_button.nav_transition(screen != main_screen)
		if screen != main_screen:
			_back_button.grab_focus()

	_current_screen = screen


func set_screen(screen: TransitionElement):
	if _current_screen:
		nav_hide()

	_current_screen = screen

	if screen:
		screen.visible = true
		screen.nav_show()

		if screen and screen != main_screen:
			_back_button.nav_show()
		else:
			_back_button.nav_hide()


func _hide_screen(screen: TransitionElement):
	screen.nav_hide()
	screen.visible = false


func _transition_screen(screen: TransitionElement, vis: bool) -> Tween:
	screen.visible = true

	var tween := screen.nav_transition(vis)
	if tween and not vis:
		tween.finished.connect(func(): _hide_screen(screen), CONNECT_ONE_SHOT)

	return tween


func _on_back_button_pressed():
	if inhibit_back:
		return

	switch_screen(main_screen)
