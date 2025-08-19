extends DebugWindow
## [Character] debug window.

const _STATE_FLAGS: Array[int] = [
	CharacterMotionState.CharacterState.IDLE,
	CharacterMotionState.CharacterState.JUMPING,
	CharacterMotionState.CharacterState.FALLING,
	CharacterMotionState.CharacterState.WALKING,
	CharacterMotionState.CharacterState.CLIMBING,
	CharacterMotionState.CharacterState.SITTING,
	CharacterMotionState.CharacterState.SWIMMING,
	CharacterMotionState.CharacterState.DEAD,
]

const _STATE_NAMES: Array[String] = [
	"IDLE",
	"JUMPING",
	"FALLING",
	"WALKING",
	"CLIMBING",
	"SITTING",
	"SWIMMING",
	"DEAD",
]

var _character: Character
@export var character: Character:
	set = _set_character,
	get = _get_character

var _physical_processor: CharacterPhysicalMotionProcessor
var _stairs_processor: CharacterStairsMotionProcessor

var _state: RichTextLabel

@onready var _tbl: DebugInfoTable = %DebugInfoTable
@onready var _dd := DebugDraw.get_singleton()


func _init():
	action = &"debug_3"


func _ready():
	super._ready()

	_state = _tbl.add_entry(&"state", "State").contents

	_tbl.add_entry(&"position", "Position")
	_tbl.add_entry(&"ragdoll", "Is Ragdoll")
	_tbl.add_entry(&"grounded", "Is Grounded")
	_tbl.add_entry(&"collisions", "Collisions")
	_tbl.add_entry(&"velocity", "Velocity")

	_update_character()


func _process(_delta: float):
	var state := character.state
	var ctx := state.ctx

	# State
	_state.clear()
	for i in range(_STATE_FLAGS.size()):
		_state.push_color(Color.GREEN if state.is_state(_STATE_FLAGS[i]) else Color.RED)
		_state.append_text(_STATE_NAMES[i])
		_state.pop()

		if i != _STATE_FLAGS.size() - 1:
			_state.newline()

	# Other
	_tbl.set_val(&"position", CommonUtils.format_vector3(state.get_bottom_position()))
	_tbl.set_val(&"ragdoll", "Yes" if state.is_ragdoll else "No")

	var grounded_str: String
	if ctx.is_grounded:
		grounded_str = "Yes"
	elif _physical_processor != null:
		grounded_str = "Airborne %.2fs" % [_physical_processor._airborne_time]
	else:
		grounded_str = "No"
	_tbl.set_val(&"grounded", grounded_str)

	(
		_tbl
		. set_val(
			&"collisions",
			(
				"Walls: %d, Bodies: %d, Areas: %d"
				% [
					ctx.walls.size(),
					ctx.body_intersections.size(),
					ctx.area_intersections.size(),
				]
			)
		)
	)

	var velocity_str := (
		"Total: %s m/s (norm: %.2f m/s)"
		% [
			CommonUtils.format_vector3(ctx.velocity),
			ctx.velocity.length(),
		]
	)

	for processor in state._motion_processors:
		var velocity: Variant = processor._get_velocity()
		if velocity != null:
			velocity_str += (
				"\n%s: %s m/s (norm: %.2f m/s)"
				% [
					processor.id,
					CommonUtils.format_vector3(velocity),
					velocity.length(),
				]
			)

	_tbl.set_val(&"velocity", velocity_str)

	_debug_draw()


func _update_character():
	if not is_inside_tree() or not character:
		return

	_physical_processor = character.state.get_motion_processor(CharacterPhysicalMotionProcessor.ID)
	_stairs_processor = character.state.get_motion_processor(CharacterStairsMotionProcessor.ID)


func _set_character(new_character: Character):
	_character = new_character
	_update_character()


func _get_character() -> Character:
	return _character


func _debug_draw():
	var state := character.state
	var ctx := state.ctx

	var pos := character.global_position
	var eye_pos := pos + character.global_basis.y * character.camera.camera_offset

	# Bottom point
	_dd.draw_marker(state.get_bottom_position(), Color.WHITE)
	# Forward direction
	_dd.draw_line(eye_pos, eye_pos - character.global_basis.z, Color.WHITE)

	# Walls
	for wall in character.state.ctx.walls:
		_dd.draw_line(wall.point, wall.point + wall.normal, Color.WHITE)

	# Grounding status
	if ctx.is_grounded:
		_dd.draw_line(pos, pos + ctx.ground_normal, Color.GREEN)
	else:
		_dd.draw_marker(pos + Vector3.UP * 0.1, Color.RED)

	# Velocities
	const VELOCITY_SCALE := 8.0
	_dd.draw_line(pos, pos + ctx.velocity / VELOCITY_SCALE, Color.BLUE)

	# Stairs
	if _stairs_processor and _stairs_processor._found_stair:
		const STAIRS_AXIS_LENGTH := 0.25

		var target := _stairs_processor._end_position

		_dd.draw_marker(_stairs_processor._begin_position, Color.AQUA)
		_dd.draw_marker(target, Color.AQUA)

		_dd.draw_line(
			target, target + _stairs_processor._wall_tangent * STAIRS_AXIS_LENGTH, Color.RED
		)

		_dd.draw_line(
			target, target + _stairs_processor._slope_normal * STAIRS_AXIS_LENGTH, Color.GREEN
		)

		_dd.draw_line(
			target, target + _stairs_processor._motion_vector * STAIRS_AXIS_LENGTH, Color.BLUE
		)
