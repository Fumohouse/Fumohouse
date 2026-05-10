extends "../character_billboard.gd"

@export var fumo: Fumo

@onready var _name: Label = %Name


func _ready():
	super()

	if fumo.multiplayer_mode == CharacterMotionState.MultiplayerMode.SINGLEPLAYER:
		hide()
		return

	_update_name()
	fumo.renamed.connect(_update_name)


func _update_name():
	_name.text = fumo.name
