--- @class PartData
--- @extends Resource
local PartData = {}
local PartDataC = gdclass(PartData)

PartData.Scope = {
    NONE = 0,
	ACCESSORY = 1,
	OUTFIT = 2,
	HAIR = 3,
	SHOES = 4,
	HAT = 5,
	EARS = 6,
	TAIL = 7,
}

--- @classType PartData
export type PartData = Resource & typeof(PartData) & {
    --- @property
    id: string,

    --- @property
    --- @enum None Accessory Outfit Hair Shoes Hat Ears Tail
    scope: integer,
}

return PartDataC
