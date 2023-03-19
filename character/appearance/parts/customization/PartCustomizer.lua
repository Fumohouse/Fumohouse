local Appearance = require("../../Appearance")

local PartCustomizerImpl = {}
local PartCustomizer = gdclass(nil, Node3D)
    :RegisterImpl(PartCustomizerImpl)

export type PartCustomizer = Node3D & typeof(PartCustomizerImpl)

function PartCustomizerImpl.Update(self: PartCustomizer, appearance: Appearance.Appearance, config: Dictionary?)
end

return PartCustomizer
