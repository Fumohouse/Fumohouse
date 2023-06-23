local PartData = require("PartData")
local SinglePart = require("SinglePart")

--- @class MultiPart
--- @extends PartData
local MultiPart = {}
local MultiPartC = gdclass(MultiPart)

--- @classType MultiPart
export type MultiPart = PartData.PartData & typeof(MultiPart) & {
    --- @property
    parts: TypedArray<SinglePart.SinglePart>,
}

return MultiPartC
