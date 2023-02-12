local PartCustomizerImpl = {}
local PartCustomizer = gdclass(nil, "Node3D")
    :RegisterImpl(PartCustomizerImpl)

export type PartCustomizer = Node3D & typeof(PartCustomizerImpl)

function PartCustomizerImpl._FHInitialize(self: PartCustomizer, config: Dictionary?)
end

return PartCustomizer