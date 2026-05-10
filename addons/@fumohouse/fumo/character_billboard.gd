extends Billboard
## A billboard that is anchored to a certain offset above the [AABB] of part of
## a character.

## Appearance manager to subscribe to updates from.
@export var appearance_manager: AppearanceManager
## Node to place this billboard above.
@export var target: Node3D
## Margin above the AABB.
@export var margin := 0.2


func _ready():
	super()
	_update_position()
	appearance_manager.appearance_loaded.connect(_update_position)


func _update_position():
	var aabb := CommonUtils.get_aabb(target, [self])
	# stupid
	position.y = (
		(target.global_position - get_parent().global_position).length()
		+ aabb.position.y
		+ aabb.size.y
		+ margin
	)
