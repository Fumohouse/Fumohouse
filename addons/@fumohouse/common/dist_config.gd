class_name DistConfig
extends Object
## Distribution configuration.

const STAGE_COLOR := "#006be3"  # hsv(203, 100%, 70%)
const STAGE_NAME := "Prototype"
const STAGE_ABBREV := "PRO"
const VERSION := "2025.08.03"


## Get the version name.
static func get_build_string():
	return STAGE_NAME + " " + VERSION
