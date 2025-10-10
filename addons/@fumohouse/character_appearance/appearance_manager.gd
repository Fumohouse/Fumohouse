@abstract class_name AppearanceManager
extends Node3D
## Class responsible for attaching [PartData] to a series of
## [BoneAttachment3D]s and managing other aspects of a character's appearance
## (in derived classes). The bone attachments should be the children of this
## node, each named after the bone name in [PartData].

## Fired whenever the appearance is loaded.
signal appearance_loaded

## The part database to find [PartData] from.
var part_database: PartDatabase

## Information about all attached parts, keyed on the part ID.
var attached_parts: Dictionary[StringName, AttachedPartInfo] = {}

## The current appearance.
@export var appearance: Appearance


func _ready():
	load_appearance.call_deferred()


## Load [member appearance].
func load_appearance():
	if not appearance:
		for id in attached_parts:
			_detach(id)
		return

	for id in appearance.attached_parts:
		_attach(id)

	for id in attached_parts:
		if appearance.attached_parts.has(id):
			var config: Variant = appearance.attached_parts[id]

			if config != null:
				for node in attached_parts[id].nodes:
					if node is PartCustomizer:
						node._update(
							config if config else attached_parts[id].part_data.default_config
						)
		else:
			_detach(id)

	_load_custom()

	appearance_loaded.emit()


## Override to load the custom options from [member appearance]. Called as thee
## last step of [method load_appearance].
func _load_custom():
	pass


func _attach_single(part: SinglePart) -> Node3D:
	var scene = load(part.scene_path)
	assert(scene is PackedScene, "Part data should point to a valid scene.")
	var node = scene.instantiate()
	assert(node is Node3D, "Attached part should be a Node3D.")

	var attachment = get_node(part.bone)
	assert(attachment != null, "Bone does not exist under this node.")
	attachment.add_child(node)
	node.transform = part.transform

	return node


func _search_materials(node: Node3D, arr: Dictionary[Material, bool]):
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var material: Material = node.get_active_material(i)
			if material and material.resource_local_to_scene:
				arr[material] = true

	for child in node.get_children():
		if child is Node3D:
			_search_materials(child, arr)


func _attach(id: StringName):
	if attached_parts.has(id):
		return

	var info := part_database.get_part(id)
	assert(info, "Part not found: %s" % [id])

	var attached_models: Array[Node3D] = []
	var tmp_arr: Dictionary[Material, bool] = {}
	var materials: Array[Material] = []

	if info is SinglePart:
		var node := _attach_single(info)
		_search_materials(node, tmp_arr)
		attached_models.push_back(node)
	elif info is MultiPart:
		for single_part in info.parts:
			var node := _attach_single(single_part)
			_search_materials(node, tmp_arr)
			attached_models.push_back(node)

	for key in tmp_arr:
		materials.push_back(key)

	var ap := AttachedPartInfo.new()
	ap.part_data = info
	ap.nodes = attached_models
	ap.materials = materials
	attached_parts[id] = ap


func _detach(id: StringName):
	if not attached_parts.has(id):
		return

	for model in attached_parts[id].nodes:
		model.queue_free()

	attached_parts.erase(id)


## Information about attached parts.
class AttachedPartInfo:
	extends Resource
	## The attached [PartData].
	var part_data: PartData
	## List of top-level node for each [SinglePart] composing the attached part.
	var nodes: Array[Node3D]
	## List of constituent materials.
	var materials: Array[Material]
