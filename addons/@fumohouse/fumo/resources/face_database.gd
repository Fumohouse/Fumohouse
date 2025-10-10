class_name FumoFaceDatabase
extends Resource
## Resource indexing all fumo face styles.

## Eyebrow styles.
@export var eyebrow_styles: Array[FumoFacePartStyle] = []

## Eye styles.
@export var eye_styles: Array[FumoEyeStyle] = []

## Mouth styles.
@export var mouth_styles: Array[FumoFacePartStyle] = []


## Get eyebrow style by [param id].
func get_eyebrow(id: StringName) -> FumoFacePartStyle:
	for style in eyebrow_styles:
		if style.id == id:
			return style
	return null


## Get eye style by [param id].
func get_eye(id: StringName) -> FumoEyeStyle:
	for style in eye_styles:
		if style.id == id:
			return style
	return null


## Get mouth style by [param id].
func get_mouth(id: StringName) -> FumoFacePartStyle:
	for style in mouth_styles:
		if style.id == id:
			return style
	return null
