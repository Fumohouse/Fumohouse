local PartData = require("PartData")

--- @class SinglePart
--- @extends PartData
--- @tool
local SinglePart = {} -- must be instantiable in the editor (addon)
local SinglePartC = gdclass(SinglePart)

export type SinglePart = PartData.PartData & {
    --- @property
    scenePath: string,

    --- @property
    transform: Transform3D,

    --- @property
    --- @enum Torso Head RArm LArm RHand LHand RLeg LLeg RFoot LFoot
    bone: integer,
}

SinglePart.BASE_PATH = "res://assets/models/characters/"

SinglePart.Bone = {
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

return SinglePartC
