local SpawnpointImpl = {}
local Spawnpoint = gdclass("Spawnpoint", Node3D)
    :RegisterImpl(SpawnpointImpl)

export type Spawnpoint = Node3D & typeof(SpawnpointImpl)

function SpawnpointImpl.GetSpawnPoint(self: Spawnpoint): Transform3D
    return (self:GetNode("Position") :: Marker3D).globalTransform
end

Spawnpoint:RegisterMethodAST("GetSpawnPoint")

return Spawnpoint
