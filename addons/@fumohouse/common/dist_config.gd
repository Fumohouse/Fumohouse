class_name DistConfig
extends Object
## Distribution configuration.

const STAGE_COLOR := "#a51a21"
const STAGE_NAME := "Developer Preview"
const STAGE_ABBREV := "DEV"
const VERSION := "2026.01.02"


## Get the version name.
static func get_build_string():
	return STAGE_NAME + " " + VERSION
