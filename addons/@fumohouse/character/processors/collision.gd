class_name CharacterCollisionMotionProcessor
extends CharacterMotionProcessor
## Handles collisions with other [RigidBody3D]s in non-ragdoll mode.

const ID := &"collision"

## Force (Newtons) to oppose the motion of the colliding object with.
var resist_force := 70.0

## Velocity induced by this processor.
var _velocity := Vector3.ZERO
## Angular velocity (rad/s) induced by this processor.
var _angular_velocity := Vector3.ZERO

var _direct_body_state: PhysicsDirectBodyState3D


func _init():
	id = ID


func _initialize():
	state.node.contact_monitor = true
	state.node.max_contacts_reported = 16
	_direct_body_state = PhysicsServer3D.body_get_direct_state(state.rid)


func _process(delta: float, cancelled: bool):
	if cancelled or state.is_ragdoll:
		_velocity = Vector3.ZERO
		_angular_velocity = Vector3.ZERO
		return

	for i in _direct_body_state.get_contact_count():
		var collider := _direct_body_state.get_contact_collider_object(i)
		var position := _direct_body_state.get_contact_local_position(i)
		var normal := _direct_body_state.get_contact_local_normal(i)
		var impulse := _direct_body_state.get_contact_impulse(i)

		var collider_mass := 1.0
		if collider is RigidBody3D:
			var rb := collider as RigidBody3D
			collider_mass = rb.mass
			rb.apply_force(-normal * resist_force)

		# https://github.com/godotengine/godot/blob/a311a4b162364d032b03ddf2a0e603ba40615ad7/servers/physics_3d/godot_body_3d.h#L227-L230
		_velocity += impulse * _direct_body_state.inverse_mass
		_angular_velocity += _direct_body_state.inverse_inertia * (position - _direct_body_state.center_of_mass).cross(impulse)

	ctx.add_offset(_velocity * delta)
	ctx.new_basis = Basis.from_euler(_angular_velocity * delta) * ctx.new_basis

	# Pretty fake physics
	_velocity = _velocity.lerp(Vector3.ZERO, CommonUtils.lerp_weight(delta, 1e-3))
	_angular_velocity = _angular_velocity.lerp(Vector3.ZERO, CommonUtils.lerp_weight(delta, 1e-3))


func _get_velocity() -> Variant:
	return _velocity
