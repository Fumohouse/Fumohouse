class_name QuitManager
extends Node
## A singleton that should be used instead of [method SceneTree.quit] to
## quit the game.

signal before_quit

const LOG_SCOPE := "QuitManager"

## Indicates whether a quit is in progress.
var is_quitting: bool:
	get:
		return _is_quitting

var _is_quitting := false
var _quit_inhibitors: Array[Callable] = []


static func get_singleton() -> QuitManager:
	return Modules.get_singleton(&"QuitManager") as QuitManager


func _ready():
	get_tree().auto_accept_quit = false


func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


## Register a function that can inhibit the quit process. [param inhibitor]
## should take no arguments and return [code]true[/code] if and only if the
## quit process should be inhibited. The inhibiting code should call
## [method quit] (and stop inhibiting) once ready.
func register_quit_inhibitor(inhibitor: Callable):
	_quit_inhibitors.push_back(inhibitor)


func quit():
	_is_quitting = true

	for inhibitor in _quit_inhibitors:
		if inhibitor.call():
			return

	# This log might not appear in the editor. Whatever
	Log.info("Quitting...", LOG_SCOPE)
	before_quit.emit()
	get_tree().quit()
