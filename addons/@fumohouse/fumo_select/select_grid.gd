extends GridContainer

# TODO: does not work well (i.e at all) with the modules design
# closest I can think to the current architecture is to add autoloads?
# to allow organizing fumo files however the author wishes instead of hardcoding a path
# that does require designing loading the other parts in the database (not handled at all)
const _PRESET_DIR = "res://addons/@fumohouse/fumo_models/resources/presets"

@onready var _item_template: Button = %FumoGridItem


func _ready():
	# making it invisible here seems comfier to edit with
	_item_template.visible = false

	# TODO: not a good idea to get_node like this
	var char_manager := get_node("/root/Playground/CharacterManager") as CharacterManagerBase
	if not char_manager:
		push_error("No character manager found.")
		return

	var preset_dir := DirAccess.open(_PRESET_DIR)
	if not preset_dir:
		push_error("Failed to open presets directory.")
		return

	preset_dir.list_dir_begin()
	while true:
		var preset_filepath := preset_dir.get_next()
		if preset_filepath == "":
			break
		# not sure if gdscript has a Path type or a join() utility function
		var preset := load(preset_dir.get_current_dir() + "/" + preset_filepath) as Appearance
		if not preset:
			push_warning("Unrecognized preset: " + preset_filepath)
			continue

		var item := _item_template.duplicate()
		item.text = preset.display_name
		item.visible = true
		# TODO: change fumos without going back to a spawnpoint
		item.pressed.connect(func(): char_manager._spawn_character(preset, null))

		self.add_child(item)
