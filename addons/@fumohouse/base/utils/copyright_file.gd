class_name CopyrightFile
extends Resource
## Parses and stores a Debian format [code]COPYRIGHT.txt[/code] file.

const LOG_SCOPE := "CopyrightFile"

## Global map of license files to licenses.
static var licenses: Dictionary[StringName, CopyrightLicense] = {}

## List of file stanzas in this copyright file.
@export var files: Array[CopyrightFiles] = []

# Parser state
var _current_files: CopyrightFiles = null
var _current_license: CopyrightLicense = null
var _current_field := ""
var _current_string := ""


## Parse the [code]COPYRIGHT.txt[/code] file at the given [param path].
func parse(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		Log.error("Failed to open COPYRIGHT file at %s." % [path], LOG_SCOPE)
		return false

	_current_files = null
	_current_license = null
	_current_field = ""
	_current_string = ""

	while not file.eof_reached():
		var line: String = file.get_line()
		var stripped: String = line.strip_edges()
		if stripped.is_empty() or stripped[0] == "#":
			continue

		if line[0] == " ":
			# Continuation line
			if _current_field.is_empty():
				continue

			if stripped == ".":
				# Empty line
				_current_string += "\n"
				continue

			if not _current_string.is_empty():
				_current_string += "\n"

			_current_string += stripped
		else:
			# Start of field
			var idx: int = stripped.find(":")
			if idx == -1:
				continue

			_push_field()

			var field: String = stripped.substr(0, idx)
			var value: String = stripped.substr(idx + 1).strip_edges()

			if field == "Files":
				_push_block()
				_current_files = CopyrightFiles.new()
				_current_string = value
			elif (
				field == "License" and (not _current_files or not _current_files.license.is_empty())
			):
				_push_block()
				_current_license = CopyrightLicense.new()
				_current_license.id = value
			else:
				_current_string = value

			_current_field = field

	_push_field()
	_push_block()

	return true


func _push_field():
	if _current_field.is_empty():
		return

	if _current_files:
		if _current_field == "Files":
			_current_files.files = _current_string.split("\n")
		elif _current_field == "Comment":
			_current_files.comment = _current_string
		elif _current_field == "Copyright":
			_current_files.copyright = _current_string.split("\n")
		elif _current_field == "License":
			_current_files.license = _current_string
	elif _current_license:
		if _current_field == "License":
			_current_license.text = _current_string

	_current_field = ""
	_current_string = ""


func _push_block():
	if _current_files:
		files.push_back(_current_files)
		_current_files = null
	elif _current_license:
		# Prevent license text from being overridden
		if _current_license.id not in licenses:
			licenses[_current_license.id] = _current_license
		_current_license = null


class CopyrightFiles:
	extends Resource
	## The files that this file stanza describes.
	@export var files: PackedStringArray = []
	## Comment if provided, e.g., description of the files.
	@export var comment := ""
	## Copyright owners.
	@export var copyright: PackedStringArray = []
	## SPDX identifier of these files.
	@export var license := &""


class CopyrightLicense:
	extends Resource
	## SPDX identifier of this license.
	@export var id := &""
	## License text.
	@export var text := ""
