@tool
extends Control

@onready var _folder_field: LineEdit = $Folder


func _ready():
	$Save.pressed.connect(_on_save_pressed)


func _on_save_pressed():
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty():
		return

	var target: Node = selected[0]

	# Prepare directory
	var folder := _folder_field.text
	assert(folder != "", "The folder field is required.")
	assert(not DirAccess.dir_exists_absolute(folder), "The folder already exists.")

	DirAccess.make_dir_absolute(folder)

	# Save
	var attachments: Node = target.get_node("Appearance")
	assert(attachments != null, "The selected node is not a valid character.")

	for attachment in attachments.get_children():
		if attachment is not BoneAttachment3D:
			continue

		for part in attachment.get_children():
			var scene_path := part.scene_file_path
			if scene_path == "":
				push_warning("Part %s not instantiated from a scene file." % part.name)
				continue

			var part_data := SinglePart.new()
			part_data.id = part.name
			part_data.scene_path = scene_path
			part_data.transform = part.transform
			part_data.bone = attachment.name

			ResourceSaver.save(part_data, "%s/%s.tres" % [folder, part.name])
