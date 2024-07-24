local Appearance = require("../../Appearance")

--- @class
--- @extends Node3D
local PartCustomizer = {}
local PartCustomizerC = gdclass(PartCustomizer)

export type PartCustomizer = Node3D & typeof(PartCustomizer)

function PartCustomizer.Update(self: PartCustomizer, appearance: Appearance.Appearance, config: Dictionary?)
end

return PartCustomizerC
