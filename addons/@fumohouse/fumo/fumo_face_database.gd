class_name FumoFaceDatabase
extends Node
## Database for fumo face styles.

const LOG_SCOPE := "FumoFaceDatabase"

## Eyebrow styles.
var eyebrow_styles: Dictionary[StringName, FumoEyebrowStyle] = {}

## Eye styles.
var eye_styles: Dictionary[StringName, FumoEyeStyle] = {}

## Mouth styles.
var mouth_styles: Dictionary[StringName, FumoMouthStyle] = {}


static func get_singleton() -> FumoFaceDatabase:
	return Modules.get_singleton(&"FumoFaceDatabase") as FumoFaceDatabase


## Scan [param dir] recursively for face data.
func scan_dir(path: String):
	var contents: PackedStringArray = ResourceLoader.list_directory(path)

	for file_name in contents:
		var full_path := path.path_join(file_name)
		if file_name.ends_with("/"):
			# Directory
			scan_dir(full_path)
		elif file_name.ends_with(".tres"):
			var res = load(full_path)

			if res is FumoEyebrowStyle:
				if eyebrow_styles.has(res.id):
					Log.error("Duplicate eyebrow ID: %s" % [res.id], LOG_SCOPE)
				else:
					eyebrow_styles[res.id] = res
			elif res is FumoEyeStyle:
				if eye_styles.has(res.id):
					Log.error("Duplicate eye ID: %s" % [res.id], LOG_SCOPE)
				else:
					eye_styles[res.id] = res
			elif res is FumoMouthStyle:
				if mouth_styles.has(res.id):
					Log.error("Duplicate mouth ID: %s" % [res.id], LOG_SCOPE)
				else:
					mouth_styles[res.id] = res


## Get eyebrow style by [param id].
func get_eyebrow(id: StringName) -> FumoEyebrowStyle:
	return eyebrow_styles.get(id)


## Get eye style by [param id].
func get_eye(id: StringName) -> FumoEyeStyle:
	return eye_styles.get(id)


## Get mouth style by [param id].
func get_mouth(id: StringName) -> FumoMouthStyle:
	return mouth_styles.get(id)
