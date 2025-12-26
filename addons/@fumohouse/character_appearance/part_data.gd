@abstract class_name PartData
extends Resource
## Resource representing a part that can be attached to a character.

## Potential areas to attach parts to.
enum Scope {
	NONE = 0,
	ACCESSORY,
	OUTFIT_FULL,
	OUTFIT_TOP,
	OUTFIT_BOTTOM,
	HAIR_FULL,
	HAIR_FRONT,
	HAIR_BACK,
	HAIR_ACCESSORY,
	SHOES,
	HAT,
	EARS,
	TAIL,
}

## Human-readable names for [enum Scope] values.
const SCOPE_NAMES: Array[StringName] = [
	"None",
	"Accessory",
	"Outfit (Full)",
	"Outfit (Top)",
	"Outfit (Bottom)",
	"Hair (Full)",
	"Hair (Front)",
	"Hair (Back)",
	"Hair (Accessory)",
	"Shoes",
	"Hat",
	"Ears",
	"Tail",
]

## Additional parameters for part slots. The value may contain the following
## fields:[br]
##
## [code]multiple[/code] ([code]bool[/code], defaults to [code]false[/code]):
## Whether selecting multiple parts for this slot should be allowed.[br]
##
## [code]exclude[/code] (Array[[enum Scope]], defaults to an empty array):
## Array of scopes that should not be attachable if this slot is taken.
const SLOT_PARAMS: Dictionary[Scope, Dictionary] = {
	Scope.ACCESSORY: {"multiple": true},
	Scope.HAIR_ACCESSORY: {"multiple": true},
	Scope.HAIR_FULL: {"exclude": [Scope.HAIR_FRONT, Scope.HAIR_BACK]},
	Scope.HAIR_FRONT: {"exclude": [Scope.HAIR_FULL]},
	Scope.HAIR_BACK: {"exclude": [Scope.HAIR_FULL]},
	Scope.OUTFIT_FULL: {"exclude": [Scope.OUTFIT_TOP, Scope.OUTFIT_BOTTOM]},
	Scope.OUTFIT_TOP: {"exclude": [Scope.OUTFIT_FULL]},
	Scope.OUTFIT_BOTTOM: {"exclude": [Scope.OUTFIT_FULL]},
}

## The display name for this part.
@export var display_name := ""

## A unique ID for this part.
@export var id := &""

## The scope that this part will be attached to.
@export_enum(
	"None",
	"Accessory",
	"Outfit (Full)",
	"Outfit (Top)",
	"Outfit (Bottom)",
	"Hair (Full)",
	"Hair (Front)",
	"Hair (Back)",
	"Hair (Accessory)",
	"Shoes",
	"Hat",
	"Ears",
	"Tail"
)
var scope: int = Scope.NONE

## Default options for this part.
@export var default_config: Dictionary[StringName, Variant] = {}
