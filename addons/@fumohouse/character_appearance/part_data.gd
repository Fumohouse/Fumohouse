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
