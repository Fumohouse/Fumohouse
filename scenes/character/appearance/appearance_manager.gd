extends Node3D

# TODO: From SinglePart
enum Bone {
	TORSO,
	HEAD,
	R_ARM,
	L_ARM,
	R_HAND,
	L_HAND,
	R_LEG,
	L_LEG,
	R_FOOT,
	L_FOOT,
}

const BASE_PATH := "res://assets/models/characters/"
#######################

const ATTACHMENTS := {
	Bone.TORSO: "Torso",
	Bone.HEAD: "Head",
	Bone.R_ARM: "RArm",
	Bone.L_ARM: "LArm",
	Bone.R_HAND: "RHand",
	Bone.L_HAND: "LHand",
	Bone.R_LEG: "RLeg",
	Bone.L_LEG: "LLeg",
	Bone.R_FOOT: "RFoot",
	Bone.L_FOOT: "LFoot",
}

const SIZES := {
	"doll": 0.5,
	"shinmy": 0.75,
	"base": 1.0,
	"deka": 3.0,
}


@export var appearance: Resource
var _appearance: Appearance :
	get:
		return appearance as Appearance

@export var camera_fade_begin := 1.5
@export var camera_fade_end := 0.25

@onready var _character: Character = get_parent()
@onready var _rig: Node3D = $"../Rig"
@onready var _skeleton: Skeleton3D = $"../Rig/Armature/Skeleton3D"
@onready var _capsule: CollisionShape3D = $"../Capsule"

@onready var _transparent_tex: Texture2D = preload("res://assets/textures/transparent.png")
@onready var _face_material: ShaderMaterial = preload("face/face_material.tres").duplicate()
@onready var _face_database: FaceDatabase = preload("res://resources/face_database.tres")
@onready var _skin_material: ShaderMaterial = _skeleton.get_node("Head").get_active_material(0)


class AttachedPartInfo:
	var nodes: Array[Node3D]
	var materials: Array[Material]


var _attached_parts := {}

var _base_camera_offset: float

var _scale := 1.0
var _alpha := 1.0


func _ready():
	var face: MeshInstance3D = _skeleton.get_node("Face")
	face.material_override = _face_material

	load_appearance()


func _set_alpha(alpha: float):
	const ALPHA_PARAM := &"alpha"

	if _alpha == alpha:
		return

	_alpha = alpha

	if _alpha == 0:
		_rig.visible = false
		visible = false
		return

	_rig.visible = true
	visible = true

	_face_material.set_shader_parameter(ALPHA_PARAM, alpha)
	_skin_material.set_shader_parameter(ALPHA_PARAM, alpha)

	for info in _attached_parts.values():
		for material in info.materials:
			if not (material is ShaderMaterial) or material.get_shader_parameter(ALPHA_PARAM) == null:
				continue

			material.set_shader_parameter(ALPHA_PARAM, alpha)


func _physics_process(_delta: float):
	if not _character.camera:
		return

	if _character.camera.camera_mode == CameraController.CameraMode.FIRST_PERSON:
		_set_alpha(0.0)
		return

	var distance: float = (
		_character.camera.global_position - _character.camera.get_focal_point()
	).length()

	var begin_scaled := camera_fade_begin * _scale
	var end_scaled := camera_fade_end * _scale

	var alpha := (distance - end_scaled) / (begin_scaled - end_scaled)
	alpha = clampf(alpha, 0.0, 1.0)

	_set_alpha(alpha)


func _on_character_camera_updated(camera):
	_base_camera_offset = _character.camera.camera_offset
	_load_scale()


func _set_face_tex(uniform: StringName, texture: Texture2D):
	_face_material.set_shader_parameter(
		uniform, texture if texture != null else _transparent_tex
	)


func _load_face_part_style(method: StringName, style_name: String, uniform: StringName):
	var texture: Texture2D

	if style_name != "":
		var style: FacePartStyle = _face_database.call(method, style_name)
		if style:
			texture = style.texture
		else:
			push_error("Failed to load face style: %s" % style_name)

	_set_face_tex(uniform, texture)


func _load_face():
	# Eyebrow & mouth
	_load_face_part_style("get_eyebrow", _appearance.eyebrows, "brow_texture")
	_load_face_part_style("get_mouth", _appearance.mouth, "mouth_texture")

	# Eyes
	var eye_name := _appearance.eyes

	var eye_texture: Texture2D
	var shine_texture: Texture2D
	var overlay_texture: Texture2D

	if eye_name != "":
		var style: EyeStyle = _face_database.get_eye(String(eye_name))
		if style:
			eye_texture = style.eyes
			shine_texture = style.shine
			overlay_texture = style.overlay

			_face_material.set_shader_parameter(
				"eye_tint",
				_appearance.eyes_color if style.supportsRecoloring else Color.WHITE
			)
		else:
			push_error("Failed to load eye style: %s" % eye_name)

	_set_face_tex("eye_texture", eye_texture)
	_set_face_tex("shine_texture", shine_texture)
	_set_face_tex("overlay_texture", overlay_texture)


func _attach_single(part_info: SinglePart, config: Dictionary) -> Node3D:
	const INIT_METHOD := &"_FHInitialize"

	var node: Node3D = load(BASE_PATH + part_info.scenePath).instantiate()

	var target_att: BoneAttachment3D = get_node(ATTACHMENTS[part_info.bone])
	target_att.add_child(node)
	node.transform = part_info.transform

	# Call AFTER _ready
	if node.has_method(INIT_METHOD):
		node.call(INIT_METHOD, config)

	return node


func _search_materials(node: Node3D, list: Array[Material] = []) -> Array[Material]:
	if node is MeshInstance3D and node.mesh:
		var mesh: Mesh = node.mesh

		for i in mesh.get_surface_count():
			var material: Material = node.get_active_material(i)
			if material and material.resource_local_to_scene and not list.has(material):
				list.append(material)

	for child in node.get_children():
		_search_materials(child, list)

	return list


func attach(id: String, config: Dictionary):
	if _attached_parts.has(id):
		return

	var info = PartDatabase.get_part(id)
	if not info:
		push_error("Part not found: %s" % id)
		return

	var attached_models: Array[Node3D] = []
	var materials: Array[Material] = []

	# if info is SinglePart:
	if info.get("parts") == null:
		var node := _attach_single(info, config)
		var found_mats := _search_materials(node)

		attached_models.append(node)
		materials.append_array(found_mats)
	# elif info is MultiPart:
	else:
		for single_part_info in info.parts:
			var node := _attach_single(single_part_info, config)
			var found_mats := _search_materials(node)

			attached_models.append(node)
			materials.append_array(found_mats)

	var part_info := AttachedPartInfo.new()
	part_info.nodes = attached_models
	part_info.materials = materials

	_attached_parts[id] = part_info


func detach(id: StringName):
	if not _attached_parts.has(id):
		return

	for model in _attached_parts[id].nodes:
		model.queue_free()

	_attached_parts.erase(id)


func _load_parts():
	var part_ids = _appearance.attached_parts.keys()

	for part_id in part_ids:
		var config = _appearance.attached_parts[part_id]
		if not (config is Dictionary):
			config = {}

		attach(part_id, config)

	for part_id in _attached_parts.keys():
		if not part_ids.has(part_id):
			detach(part_id)


func _load_scale():
	var size_id := _appearance.size
	if not SIZES.has(size_id):
		push_error("Unknown size: %s", size_id)
		return

	_scale = SIZES[size_id]
	var scale_vec := Vector3.ONE * _scale

	_rig.scale = scale_vec
	_rig.transform.origin = Vector3.ZERO

	_capsule.scale = scale_vec
	_capsule.transform.origin = Vector3.UP * _capsule.shape.height * _scale / 2

	if _character.camera:
		_character.camera.camera_offset = _base_camera_offset * _scale


func load_appearance():
	_load_face()
	_load_parts()
	_load_scale()
