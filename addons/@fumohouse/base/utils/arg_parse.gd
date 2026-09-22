class_name ArgParse
extends RefCounted
## Utility class for parsing command-line arguments.


## Parse arguments from [param argv] into [param argd_out] and [param argv_out].
## [code]argd[/code] maps key-value arguments to their value (or empty if there
## is no value). Keys start with [code]--[/code]. The value can be set either
## through [code]=[/code] or the next argument that doesn't start with
## [code]--[/code]. All unmapped values are placed in [code]argv[/code].
static func parse(
	argv: PackedStringArray, argd_out: Dictionary[StringName, String], argv_out: PackedStringArray
):
	var i := 0

	while i < argv.size():
		var arg := argv[i]
		if not arg.begins_with("--"):
			argv_out.append(arg)
			i += 1
			continue

		var arg_split: PackedStringArray = arg.split("=")
		if arg_split.size() >= 2:
			argd_out[StringName(arg_split[0].substr(2))] = "=".join(arg_split.slice(1))
			i += 1
		elif i < argv.size() - 1 and not argv[i + 1].begins_with("--"):
			argd_out[StringName(arg.substr(2))] = argv[i + 1]
			i += 2
		else:
			argd_out[StringName(arg.substr(2))] = ""
			i += 1
