class_name PartData
extends Resource


enum Scope {
	NONE,
	ACCESSORY,
	OUTFIT,
	HAIR,
	SHOES,
	HAT,
	EARS,
	TAIL,
}


@export var id := &"MyPart"

@export_enum( \
	"None",
	"Accessory",
	"Outfit",
	"Hair",
	"Shoes",
	"Hat",
	"Ears",
	"Tail"
)
var _scope := 0

var scope: Scope :
	get:
		return _scope as Scope
