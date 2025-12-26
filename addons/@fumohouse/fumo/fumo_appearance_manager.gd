class_name FumoAppearanceManager
extends AppearanceManager
## The appearance manager for fumo models.

const FACE_DATABASE: FumoFaceDatabase = preload("./resources/face_database.tres")

## The fumo to manage the appearance of.
@export var fumo: Fumo
## The rig (parent of the armature) of [member fumo].
@export var rig: Node3D

## The main collider.
@export var main_collider: CollisionShape3D
## The ragdoll collider.
@export var ragdoll_collider: CollisionShape3D

## The base camera offset, to be multiplied by the the appearance scale and
## assigned to the camera on apply.
@export var base_camera_offset := 2.5

var _base_ragdoll_collider_position := Vector3.ZERO


func _ready():
	super()
	part_database = FumoPartDatabase.get_singleton()

	# Requires parent attributes to be present
	_on_fumo_camera_updated.call_deferred(fumo.camera)
	fumo.camera_updated.connect(_on_fumo_camera_updated)

	_base_ragdoll_collider_position = ragdoll_collider.position


## Get the scale set by [member appearance].
func get_appearance_scale() -> float:
	if not appearance:
		return 1.0

	var scale: Variant = appearance.config.get(&"scale")
	return scale if scale is float else 1.0


func _load_custom():
	_load_face()
	_load_scale()


func _load_face():
	var cfg := appearance.config
	var eyebrows: Variant = cfg.get(&"eyebrows")
	var eyes: Variant = cfg.get(&"eyes")
	var mouth: Variant = cfg.get(&"mouth")
	var eyes_color: Variant = cfg.get(&"eyes_color")

	# Eyebrows
	var brow_texture: Texture2D = null

	if eyebrows is StringName:
		var st := FACE_DATABASE.get_eyebrow(eyebrows)
		assert(st, "Failed to load eyebrows: %s" % [eyebrows])
		brow_texture = st.texture

	fumo.face_material.set_shader_parameter(&"brow_texture", brow_texture)

	# Mouth
	var mouth_texture: Texture2D = null

	if mouth is StringName:
		var st := FACE_DATABASE.get_mouth(mouth)
		assert(st, "Failed to load mouth: %s" % [mouth])
		mouth_texture = st.texture

	fumo.face_material.set_shader_parameter(&"mouth_texture", mouth_texture)

	# Eyes
	var eye_texture: Texture2D = null
	var shine_texture: Texture2D = null
	var overlay_texture: Texture2D = null

	if eyes is StringName and not eyes.is_empty():
		var st := FACE_DATABASE.get_eye(eyes)
		assert(st, "Failed to load eyes: %s" % [eyes])

		eye_texture = st.eyes
		shine_texture = st.shine
		overlay_texture = st.overlay

		fumo.face_material.set_shader_parameter(
			&"eye_tint",
			eyes_color if eyes_color is Color and st.supports_recoloring else Color.WHITE
		)

	fumo.face_material.set_shader_parameter(&"eye_texture", eye_texture)
	fumo.face_material.set_shader_parameter(&"shine_texture", shine_texture)
	fumo.face_material.set_shader_parameter(&"overlay_texture", overlay_texture)


func _load_scale():
	var act_scale := get_appearance_scale()
	var scale_vec := Vector3.ONE * act_scale

	rig.scale = scale_vec
	rig.position = Vector3.ZERO

	main_collider.scale = scale_vec
	main_collider.position = Vector3.UP * fumo.state.main_collision_shape.height * act_scale / 2.0

	ragdoll_collider.scale = scale_vec
	ragdoll_collider.position = _base_ragdoll_collider_position * act_scale

	if fumo.camera:
		fumo.camera.camera_offset = base_camera_offset * act_scale


func _on_fumo_camera_updated(new_camera: CameraController):
	if not new_camera:
		return
	_load_scale()
