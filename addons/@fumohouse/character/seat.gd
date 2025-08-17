class_name Seat
extends StaticBody3D
## A seat that a [Character] can sit in.

var _occupant_internal: RigidBody3D
## The rigidbody currently occupying this seat.
@export var occupant: RigidBody3D: set = _set_occupant, get = _get_occupant
## A marker (probably [Marker3D]) that indicates where the character will be
## seated.
@export var marker: Node3D

var _occupant_mode: PhysicsServer3D.BodyMode


func _set_occupant(new_occupant: RigidBody3D):
	if new_occupant != occupant:
		if occupant:
			PhysicsServer3D.body_set_mode(occupant.get_rid(), _occupant_mode)

		if new_occupant:
			_occupant_mode = PhysicsServer3D.body_get_mode(new_occupant.get_rid())
			PhysicsServer3D.body_set_mode(new_occupant.get_rid(), PhysicsServer3D.BODY_MODE_STATIC)

		_occupant_internal = new_occupant

	if new_occupant:
		var pivot: Vector3
		var char := new_occupant as Character
		if char:
			pivot = char.state.get_bottom_position()
		else:
			pivot = new_occupant.global_position

		var pivot_offset := pivot - new_occupant.global_position
		new_occupant.global_transform = marker.global_transform.translated(-pivot_offset)


func _get_occupant() -> RigidBody3D:
	return _occupant_internal
