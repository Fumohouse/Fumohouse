@tool
class_name BaseUtils
extends RefCounted
## Utilities for the base package.


## Find the SHA256 hash of the given [param path].
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
