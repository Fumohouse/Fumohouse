local PartCustomizer = require("../../../../character/appearance/parts/customization/PartCustomizer")
local PartData = require("../../../../character/appearance/parts/PartData")
local Appearance = require("../../../../character/appearance/Appearance")

--- @class
--- @extends PartCustomizer
local DoremyHair = {}
local DoremyHairC = gdclass(DoremyHair)

--- @classType DoremyHair
export type DoremyHair = PartCustomizer.PartCustomizer & typeof(DoremyHair) & {
    ponytail: Node3D,
}

--- @registerMethod
function DoremyHair._Ready(self: DoremyHair)
    self.ponytail = self:GetNode("doremy_ponytail") :: Node3D
end

function DoremyHair.Update(self: DoremyHair, appearance: Appearance.Appearance, config: Dictionary?)
    self.ponytail.visible = #appearance:GetPartsOfScope(PartData.Scope.HAT) == 0
end

return DoremyHairC
