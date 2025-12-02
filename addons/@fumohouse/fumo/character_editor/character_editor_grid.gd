extends GridContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _item_template: Button = %FumoGridItem


func _ready():
	# making it invisible here seems comfier to edit with
	_item_template.visible = false

	scan_dir("res://addons/@fumohouse/fumo_models/resources/presets")


## Scan [param dir] recursively for model presets.
func scan_dir(path: String):
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Failed to open presets directory.")
		return

	dir.list_dir_begin()
	while true:
		var filepath := dir.get_next()
		if filepath == "":
			break

		if dir.current_is_dir():
			scan_dir(path.path_join(filepath))
			continue

		var preset := load(path.path_join(filepath)) as Appearance
		if not preset:
			push_warning("Unrecognized preset: " + filepath)
			continue

		var item := _item_template.duplicate()
		item.text = preset.display_name
		item.visible = true
		# TODO: change fumos without going back to a spawnpoint
		item.pressed.connect(func(): fumo_appearances.apply(preset))

		self.add_child(item)
