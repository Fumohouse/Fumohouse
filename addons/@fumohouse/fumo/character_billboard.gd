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
	# this is stupid
	for i in 2:
		await get_tree().process_frame

	# this is less stupid
	var aabb := CommonUtils.get_aabb(target, [self], true)
	var local_aabb: AABB = (
		get_parent().global_transform.affine_inverse() * target.get_parent().global_transform * aabb
	)
	position.y = (
		local_aabb.position.y + local_aabb.size.y + margin / get_parent().global_basis.get_scale().y
	)
