extends Billboard

@export var fumo: Fumo
@export var margin := 0.3

@onready var _name: Label = %Name


func _ready():
	super()

	if fumo.multiplayer_mode == CharacterMotionState.MultiplayerMode.SINGLEPLAYER:
		hide()
		return

	_update_name()
	fumo.renamed.connect(_update_name)
	_update_position()
	fumo.appearance_manager.appearance_loaded.connect(_update_position)


func _update_name():
	_name.text = fumo.name


func _update_position():
	var aabb := CommonUtils.get_aabb(get_parent(), [self])
	position.y = (aabb.position.y + aabb.size.y + margin)
