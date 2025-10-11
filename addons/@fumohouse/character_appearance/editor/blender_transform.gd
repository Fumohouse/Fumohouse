@tool
extends Button

@onready var _selection: EditorSelection = $"../../".plugin.get_editor_interface().get_selection()


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	var selected := _selection.get_selected_nodes()
	if selected.is_empty():
		return

	var clipboard := DisplayServer.clipboard_get()
	var transforms := _parse_transforms(clipboard)

	for node in selected:
		if node is not Node3D:
			continue

		var transform: Variant = transforms.get(node.name)
		if transform != null:
			node.global_transform = transform as Transform3D
		else:
			push_warning("No matching Blender object found for node %s." % [node.name])


func _parse_transforms(str: String) -> Dictionary:
	var transforms := {}

	var lines := str.replace("\r\n", "\n").split("\n")

	for line in lines:
		var cols := line.split("\t")
		var node_name := StringName("\t".join(cols.slice(0, -1)))
		var transform_str := cols[cols.size() - 1]
		assert(
			transform_str[0] == "(" and transform_str[transform_str.length() - 1] == ")",
			"Expected transform to be enclosed by parentheses."
		)
		var nums := transform_str.substr(1, transform_str.length() - 2).split(",")
		assert(nums.size() == 16, "Invalid transform. Expected 16 transform components.")

		"""
		x    y    z    trns
		[00] [01] [02] [03]
		[04] [05] [06] [07]
		[08] [09] [10] [11]
		[12] [13] [14] [15]
		"""

		var origin := Vector3(float(nums[3]), float(nums[7]), float(nums[11]))

		var basis_orig := Basis(
			Vector3(float(nums[0]), float(nums[4]), float(nums[8])),
			Vector3(float(nums[2]), float(nums[6]), float(nums[10])),
			-Vector3(float(nums[1]), float(nums[5]), float(nums[9])),
		)

		# No idea
		transforms[node_name] = Transform3D(basis_orig, Vector3.ZERO).rotated(
			Vector3.RIGHT, -PI / 2.0
		)

	return transforms
