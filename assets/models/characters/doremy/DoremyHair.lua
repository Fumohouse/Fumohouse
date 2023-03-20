local PartCustomizer = require("../../../../character/appearance/parts/customization/PartCustomizer")
local PartData = require("../../../../character/appearance/parts/PartData")
local Appearance = require("../../../../character/appearance/Appearance")

local DoremyHairImpl = {}
local DoremyHair = gdclass(nil, PartCustomizer)
    :RegisterImpl(DoremyHairImpl)

export type DoremyHair = PartCustomizer.PartCustomizer & typeof(DoremyHairImpl) & {
    ponytail: Node3D,
}

function DoremyHairImpl._Ready(self: DoremyHair)
    self.ponytail = self:GetNode("doremy_ponytail") :: Node3D
end

DoremyHair:RegisterMethod("_Ready")

function DoremyHairImpl.Update(self: DoremyHair, appearance: Appearance.Appearance, config: Dictionary?)
    self.ponytail.visible = appearance:GetPartOfScope(PartData.Scope.HAT) == nil
end

return DoremyHair
