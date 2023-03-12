local PartData = require("PartData")
local SinglePart = require("SinglePart")

local MultiPart = gdclass("MultiPart", PartData)

export type MultiPart = PartData.PartData & {
    parts: TypedArray<SinglePart.SinglePart>,
}

MultiPart:RegisterProperty("parts", Enum.VariantType.ARRAY)
    :TypedArray(SinglePart)

return MultiPart
