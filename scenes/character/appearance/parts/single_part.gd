class_name SinglePart
extends PartData


enum Bone {
	TORSO,
	HEAD,
	R_ARM,
	L_ARM,
	R_HAND,
	L_HAND,
	R_LEG,
	L_LEG,
	R_FOOT,
	L_FOOT,
}


const BASE_PATH := "res://assets/models/characters/"

@export var scene_path: String
@export var transform: Transform3D

@export_enum( \
	"Torso", "Head",
	"RArm", "LArm",
	"RHand", "LHand",
	"RLeg", "LLeg",
	"RFoot", "LFoot"
)
var _bone := 0

var bone: Bone :
	get:
		return _bone as Bone
