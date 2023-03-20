local PartDataImpl = {}
local PartData = gdclass("PartData", Resource)
    :RegisterImpl(PartDataImpl)

PartDataImpl.Scope = {
    NONE = 0,
	ACCESSORY = 1,
	OUTFIT = 2,
	HAIR = 3,
	SHOES = 4,
	HAT = 5,
	EARS = 6,
	TAIL = 7,
}

export type PartData = Resource & {
    id: string,
    scope: number,
}

PartData:RegisterProperty("id", Enum.VariantType.STRING)
PartData:RegisterProperty("scope", Enum.VariantType.INT)
    :Enum(
        "None",
        "Accessory",
        "Outfit",
        "Hair",
        "Shoes",
        "Hat",
        "Ears",
        "Tail"
    )

return PartData
