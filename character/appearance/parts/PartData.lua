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

type PartDataT = {
    id: string,
    scope: number,
}

export type PartData = Resource & PartDataT

PartData:RegisterProperty("id", Enum.VariantType.STRING)
    :Default("MyPart")

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
