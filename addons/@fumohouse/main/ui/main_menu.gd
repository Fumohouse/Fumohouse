extends "res://addons/@fumohouse/navigation/nav_menu.gd"

var transition_in := true

@onready var _dim: ColorRect = $Dim

@onready var _options_button: Button = %OptionsButton
@onready var _exit_button: Button = %ExitButton

@onready var _options_screen: TransitionElement = $Screens/OptionsScreen


func _ready():
	super()

	if transition_in:
		await get_tree().create_timer(0.05).timeout
		dim(false)
		switch_screen(main_screen)

	_options_button.pressed.connect(func(): switch_screen(_options_screen))
	_exit_button.pressed.connect(_on_exit_button_pressed)

	for button: Button in $Screens/MainScreen/MainButtons.get_children():
		if [_options_button, _exit_button].has(button):
			continue
		button.pressed.connect(func(): switch_screen(null))


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
