class_name QuitManager
extends Node
## A singleton that should be used instead of [method SceneTree.quit] to
## quit the game.

signal before_quit


func _ready():
	get_tree().auto_accept_quit = false


func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


static func get_singleton() -> QuitManager:
	return Modules.get_singleton("QuitManager") as QuitManager


func quit():
	# TODO: Can add some inhibitors here (e.g., for NetworkManager)

	# This log might not appear in the editor. Whatever
	print("[QuitManager] Quitting...")
	before_quit.emit()
	get_tree().quit()
