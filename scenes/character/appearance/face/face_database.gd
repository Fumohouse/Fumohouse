class_name FaceDatabase
extends Resource


@export var eyebrow_styles: Array[Resource] = []
@export var eye_styles: Array[Resource] = []
@export var mouth_styles: Array[Resource] = []


static func _find_by_name(name: StringName, array: Array[Resource]) -> Resource:
	for item in array:
		if item.name == name:
			return item

	return null


func get_eyebrow(name: StringName) -> FacePartStyle:
	return _find_by_name(name, eyebrow_styles)


func get_eye(name: StringName) -> EyeStyle:
	return _find_by_name(name, eye_styles)


func get_mouth(name: StringName) -> FacePartStyle:
	return _find_by_name(name, mouth_styles)
