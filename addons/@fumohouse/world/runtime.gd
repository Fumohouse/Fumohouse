class_name WorldRuntime
extends Node3D
## Node containing runtime components, including player characters, camera, and
## HUD.

const DebugCharacter := preload("res://addons/@fumohouse/character/debug_character.gd")

## Camera to use for the local character.
@export var camera: CameraController
## Debug overlay to bind to the local character.
@export var debug_character: DebugCharacter
