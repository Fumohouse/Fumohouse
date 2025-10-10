@abstract class_name PartDatabase
extends Node
## Abstract class for a database of [PartData]. Child classes should be a
## singleton.

## Dictionary of part keys to part data.
var parts: Dictionary[StringName, PartData] = {}


## Scan [param dir] recursively for part data.
func scan_dir(path: String):
	var dir := DirAccess.open(path)
	assert(dir, "Failed to open directory %s." % [dir])

	dir.list_dir_begin()

	var file_name := dir.get_next()

	while not file_name.is_empty():
		if dir.current_is_dir():
			scan_dir("%s/%s/" % [path, file_name])
		elif file_name.ends_with(".tres"):
			var part_info = load(path + "/" + file_name)

			if part_info is PartData:
				if parts.has(part_info.id):
					push_error("Duplicate part ID: %s" % [part_info.id])
				else:
					parts[part_info.id] = part_info

		file_name = dir.get_next()


## Get the part with the given [param id] or [code]null[/code] if not found.
func get_part(id: StringName) -> PartData:
	return parts.get(id)
