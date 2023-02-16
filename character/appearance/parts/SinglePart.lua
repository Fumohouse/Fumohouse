local PartData = require("PartData")

local SinglePartImpl = {}
local SinglePart = gdclass("SinglePart", "PartData.lua")
    :Tool(true) -- must be instantiable in the editor
    :RegisterImpl(SinglePartImpl)

export type SinglePart = PartData.PartData & {
    scenePath: string,
    transform: Transform3D,
    bone: number,
}

SinglePartImpl.BASE_PATH = "res://assets/models/characters/"

SinglePartImpl.Bone = {
	TORSO = 0,
	HEAD = 1,
	R_ARM = 2,
	L_ARM = 3,
	R_HAND = 4,
	L_HAND = 5,
	R_LEG = 6,
	L_LEG = 7,
	R_FOOT = 8,
	L_FOOT = 9,
}

SinglePart:RegisterProperty("scenePath", Enum.VariantType.STRING)
SinglePart:RegisterProperty("transform", Enum.VariantType.TRANSFORM3D)

SinglePart:RegisterProperty("bone", Enum.VariantType.INT)
    :Enum(
        "Torso", "Head",
        "RArm", "LArm",
        "RHand", "LHand",
        "RLeg", "LLeg",
        "RFoot", "LFoot"
    )

return SinglePart
