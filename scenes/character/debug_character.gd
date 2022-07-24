extends DebugMenu


var _character: Character
@export_node_path(RigidDynamicBody3D) var character: NodePath

var _state: RichTextLabel


func _init():
	menu_name = "character_debug"
	action = "debug_1"


func _ready():
	super._ready()

	_update_character()

	add_entry("state", "State")
	_state = get_entry("state").contents

	add_entry("grounded", "Is Grounded")
	add_entry("airborne", "Airborne Time")
	add_entry("speed", "Speed")


func _process(_delta: float):
	_state.clear()

	# State
	var states := Character.CharacterState.keys()

	for idx in range(states.size()):
		if idx == 0: # NONE
			continue

		var state_name: String = states[idx]

		_state.push_color(Color.GREEN \
				if _character.is_state(Character.CharacterState[state_name]) \
				else Color.RED)

		_state.append_text(state_name)
		_state.pop()

		if idx != states.size() - 1:
			_state.newline()

	# Other
	set_val("grounded", "Yes" if _character._is_grounded else "No")
	set_val("airborne", "%.3f sec" % _character._airborne_time)
	set_val("speed", "%.3f m/s" % _character._velocity.length())


func _update_character():
	if not is_inside_tree():
		return

	if not character.is_empty():
		_character = get_node(character) as Character
