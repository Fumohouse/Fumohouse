@tool
extends Control


@onready var _folder_field: LineEdit = $Folder
@onready var _plugin: EditorPlugin = get_parent().plugin
@onready var _selection: EditorSelection = _plugin.get_editor_interface().get_selection()


func _on_button_pressed():
	var part_info_path: String = \
			preload("res://scenes/character/appearance/parts/part_database.gd").PART_INFO_PATH

	var attachment_map: Dictionary = \
			preload("res://scenes/character/appearance/appearance_manager.gd").ATTACHMENTS

	# Selection
	var selected := _selection.get_selected_nodes()
	if selected.is_empty():
		return

	var target := selected[0]
	if not target is Character:
		push_warning("Selected node is not a character.")
		return

	# Prepare directory
	var folder := _folder_field.text

	if folder == "":
		push_error("The folder field is required.")
		return

	var folder_path := part_info_path + folder + "/"

	var directory := Directory.new()

	if directory.dir_exists(folder_path):
		push_error("The directory already exists.")
		return

	if directory.open(part_info_path) != OK:
		push_error("Failed to open part info directory.")
		return

	if directory.make_dir(folder_path) != OK:
		push_error("Failed to make directory.")
		return

	# Save
	var attachments: Node = target.get_node("Appearance")

	for attachment in attachments.get_children():
		if not attachment is BoneAttachment3D:
			return

		var bone: SinglePart.Bone

		for key in attachment_map.keys():
			if attachment_map[key] == attachment.name:
				bone = key

		for part in attachment.get_children():
			var scene_path: String = part.scene_file_path
			if scene_path == "":
				push_warning("Part %s is not instantiated from a scene file." % part.name)
				continue

			if not scene_path.begins_with(SinglePart.BASE_PATH):
				push_warning(
					"Part %s is instantiated from a scene not under %s"
							% [part.name, SinglePart.BASE_PATH]
				)
				continue

			scene_path = scene_path.substr(SinglePart.BASE_PATH.length())

			var part_data := SinglePart.new()
			part_data.id = part.name
			part_data.scene_path = scene_path
			part_data.transform = part.transform
			part_data._bone = bone

			ResourceSaver.save(
				folder_path + "%s_%s.tres" % [attachment.name, part.name],
				part_data
			)