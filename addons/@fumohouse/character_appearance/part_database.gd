@abstract class_name PartDatabase
extends Node
## Abstract class for a database of [PartData]. Child classes should be a
## singleton.

const LOG_SCOPE := "PartDatabase"

## Dictionary of part keys to part data.
var parts: Dictionary[StringName, PartData] = {}


## Scan [param dir] recursively for part data.
func scan_dir(path: String):
	var contents: PackedStringArray = ResourceLoader.list_directory(path)

	for file_name in contents:
		var full_path := path.path_join(file_name)
		if file_name.ends_with("/"):
			# Directory
			scan_dir(full_path)
		elif file_name.ends_with(".tres"):
			var part_info = load(full_path)

			if part_info is PartData:
				if parts.has(part_info.id):
					Log.error("Duplicate part ID: %s" % [part_info.id], LOG_SCOPE)
				else:
					parts[part_info.id] = part_info


## Get the part with the given [param id] or [code]null[/code] if not found.
func get_part(id: StringName) -> PartData:
	return parts.get(id)
