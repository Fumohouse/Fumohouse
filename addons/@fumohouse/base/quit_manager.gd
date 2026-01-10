class_name QuitManager
extends Node
## A singleton that should be used instead of [method SceneTree.quit] to
## quit the game.

signal before_quit

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
	for inhibitor in _quit_inhibitors:
		if inhibitor.call():
			return

	# This log might not appear in the editor. Whatever
	print("[QuitManager] Quitting...")
	before_quit.emit()
	get_tree().quit()
