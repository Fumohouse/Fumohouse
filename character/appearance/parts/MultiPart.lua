local PartData = require("PartData")

local MultiPart = gdclass("MultiPart", "PartData.lua")

export type MultiPart = PartData.PartData & {
    parts: TypedArray<Resource>,
}

MultiPart:RegisterProperty("parts", Enum.VariantType.ARRAY)
    :TypedArray("Resource", true)

return MultiPart
