class_name Fumo
extends Character
## Playable fumo character.

const _FACE_MAT: ShaderMaterial = preload("./resources/face_material.tres")

## The appearance manager for this fumo.
@export var appearance_manager: FumoAppearanceManager
## The rig (parent of the armature) of this fumo.
@export var rig: Node3D

## Camera distance from the fumo to begin fading out the character.
@export var camera_fade_begin := 1.5
## Camera distance from the fumo to fully fade out the character.
@export var camera_fade_end := 0.25

var face_material: ShaderMaterial
var skin_material: ShaderMaterial

var _dissolve := 0.0
var _alpha := 1.0
var _rig_alpha := 1.0

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var _head: MeshInstance3D = $Rig/Armature/Skeleton3D/HeadModel


func _ready():
	super()
	state.add_processor(FumoAnimatorMotionProcessor.new())

	face_material = _FACE_MAT.duplicate() as ShaderMaterial
	skin_material = _head.get_active_material(0) as ShaderMaterial

	_head.material_override = face_material

	appearance_manager.appearance_loaded.connect(_on_appearance_loaded)


func _process(delta: float):
	_update_camera_alpha()


## Set the dissolve of this fumo and its attached parts, where [code]1.0[/code]
## is fully dissolved. If [param force], apply the operation even if the given value matches the
## already set value.
func set_dissolve(dissolve: float, force: bool = false):
	if _dissolve == dissolve and not force:
		return

	_dissolve = dissolve
	_set_rig_shader_parameter(&"dissolve", dissolve)
	_set_attachment_shader_parameter(&"dissolve", dissolve)


## Set the rig (not attachment) alpha to [param alpha]. Used for display
## purposes.
func set_rig_alpha(alpha: float):
	_rig_alpha = alpha
	_set_rig_shader_parameter(&"alpha", alpha * _alpha)


func _set_alpha(alpha: float, force: bool = false):
	if _alpha == alpha and not force:
		return

	_alpha = alpha

	if alpha == 0.0:
		rig.hide()
		hide()
		return

	rig.show()
	show()

	_set_rig_shader_parameter(&"alpha", _rig_alpha * alpha)
	_set_attachment_shader_parameter(&"alpha", alpha)


func _set_rig_shader_parameter(param: StringName, value: Variant):
	face_material.set_shader_parameter(param, value)
	skin_material.set_shader_parameter(param, value)


func _set_attachment_shader_parameter(param: StringName, value: Variant):
	for id in appearance_manager.attached_parts:
		for material in appearance_manager.attached_parts[id].materials:
			if material is not ShaderMaterial:
				continue

			material.set_shader_parameter(param, value)


func _update_camera_alpha():
	if not camera:
		return

	if camera.mode == CameraController.CameraMode.MODE_FIRST_PERSON:
		_set_alpha(0.0)
		return

	var distance := (camera.global_position - camera.get_focal_point()).length()

	var begin_scaled := camera_fade_begin * appearance_manager.get_appearance_scale()
	var end_scaled := camera_fade_end * appearance_manager.get_appearance_scale()

	var alpha := (distance - end_scaled) / (begin_scaled - end_scaled)
	alpha = clampf(alpha, 0.0, 1.0)
	_set_alpha(alpha)


func _on_appearance_loaded():
	set_dissolve(_dissolve, true)
	_set_alpha(_alpha, true)
