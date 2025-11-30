class_name MainMenu  # for typing of _get_main_scene etc.
extends "res://addons/@fumohouse/navigation/nav_menu.gd"

var transition_in := true

@onready var _dim: ColorRect = $Dim

@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _exit_button: Button = %ExitButton

@onready var _play_screen: TransitionElement = $Screens/PlayScreen
@onready var _options_screen: TransitionElement = $Screens/OptionsScreen

@onready var _wm := WorldManager.get_singleton()


static func _get_main_scene() -> Node:
	var main_scene: PackedScene = load("res://addons/@fumohouse/main/main.tscn")
	var main_menu: MainMenu = main_scene.instantiate()
	main_menu.transition_in = false

	return main_menu


static func _prepare_main_scene(node: Node, prev_scene: Node):
	var main_menu = node as MainMenu
	if not main_menu:
		return

	main_menu.modulate = Color.TRANSPARENT
	var tween := main_menu.create_tween()
	tween.tween_property(main_menu, "modulate", Color.WHITE, 0.5)
	main_menu.dim(false)
	main_menu.switch_screen(main_menu.main_screen)

	if prev_scene:
		await tween.finished
		prev_scene.queue_free()


func _ready():
	super()

	if transition_in:
		await get_tree().create_timer(0.05).timeout
		dim(false)
		switch_screen(main_screen)

	_play_button.pressed.connect(func(): switch_screen(_play_screen))
	_options_button.pressed.connect(func(): switch_screen(_options_screen))
	_exit_button.pressed.connect(_on_exit_button_pressed)

	_wm.get_main_scene = _get_main_scene
	_wm.prepare_main_scene = _prepare_main_scene
	_wm.play_title_playlist()


func dim(vis: bool) -> Tween:
	_dim.visible = true

	var duration := (
		1.5 * MenuUtils.TRANSITION_DURATION if vis else 0.5 * MenuUtils.TRANSITION_DURATION
	)

	var tween := create_tween()
	tween.tween_property(_dim, "modulate", Color.WHITE if vis else Color.TRANSPARENT, duration)

	if not vis:
		tween.finished.connect(func(): _dim.visible = false, CONNECT_ONE_SHOT)

	return tween


func _on_exit_button_pressed():
	inhibit_back = true
	switch_screen(null)

	var dim_tween := dim(true)
	await dim_tween.finished
	await get_tree().create_timer(0.1).timeout

	QuitManager.get_singleton().quit()
