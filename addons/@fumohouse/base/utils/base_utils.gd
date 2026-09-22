@tool
class_name BaseUtils
extends RefCounted
## Utilities for the base package.


## Get the Godot Engine version string.
static func get_engine_version_string() -> String:
	var version_info: Dictionary = Engine.get_version_info()
	return (
		"%d.%d.%d.%s.%s.%s"
		% [
			version_info["major"],
			version_info["minor"],
			version_info["patch"],
			version_info["status"],
			version_info["build"],
			version_info["hash"].substr(0, 8),
		]
	)


## Get the location of the main PCK file. Implementation depends on platform.
static func get_main_pck_path() -> String:
	var exec := OS.get_executable_path()

	match OS.get_name():
		"macOS":
			# Executable is in Fumohouse.app/Contents/MacOS/Fumohouse
			# PCK is in Fumohouse.app/Contents/Resources/Fumohouse.pck
			return exec.get_base_dir().get_base_dir().path_join(
				"Resources/%s.pck" % exec.get_file().get_basename()
			)

	return exec.get_base_dir().path_join(exec.get_file().get_basename() + ".pck")


## Find the SHA256 hash of the given file [param path].
static func hash_file(path: String) -> String:
	# https://docs.godotengine.org/en/stable/classes/class_hashingcontext.html
	const CHUNK_SIZE := 1024

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""

	while file.get_position() < file.get_length():
		var remaining = file.get_length() - file.get_position()
		ctx.update(file.get_buffer(min(remaining, CHUNK_SIZE)))

	var res: PackedByteArray = ctx.finish()
	return res.hex_encode()


## Find the SHA256 of the given directory [param path]. This is the hash of each
## filename and its SHA256 hash, separated by tab, lexicographically sorted in
## ascending order. The paths are relative to [param path].
static func hash_dir(path: String) -> String:
	var files: PackedStringArray = []
	_hash_dir_internal(path, path, files)
	files.sort()

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update("\n".join(files).to_utf8_buffer())

	var res: PackedByteArray = ctx.finish()
	return res.hex_encode()


static func _hash_dir_internal(base_path: String, path: String, out: PackedStringArray):
	var dir := DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			_hash_dir_internal(base_path, full_path, out)
		else:
			out.append(
				full_path.substr(base_path.length()).trim_prefix("/") + "\t" + hash_file(full_path)
			)
		file_name = dir.get_next()
