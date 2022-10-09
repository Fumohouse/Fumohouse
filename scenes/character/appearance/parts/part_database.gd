extends Node


const PART_INFO_PATH := "res://resources/part_data/"

var _parts := {}


func _scan_dir(path: String):
	print("Scanning path: %s" % path)

	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Failed to open directory: %s" % path)
		return

	dir.include_navigational = false
	dir.list_dir_begin()

	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			_scan_dir(path + file_name + "/")
		elif file_name.ends_with(".tres"):
			var part_info: PartData = load(path + file_name)
			var id := part_info.id

			if _parts.has(id):
				push_error("Duplicate part ID: %s" % id)
			else:
				print("\tFound part: %s" % id)
				_parts[id] = part_info

		file_name = dir.get_next()


func _ready():
	print("---- PartDatabase beginning load ----")
	_scan_dir(PART_INFO_PATH)
	print("---- Finished loading %d parts. ----" % _parts.size())


func get_part(id: StringName) -> PartData:
	return _parts.get(id)
