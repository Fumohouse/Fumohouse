local SpawnpointImpl = {}
local Spawnpoint = gdclass("Spawnpoint", Node3D)
    :RegisterImpl(SpawnpointImpl)

export type Spawnpoint = Node3D & typeof(SpawnpointImpl)

function SpawnpointImpl.GetSpawnPoint(self: Spawnpoint): Transform3D
    return (assert(self:GetNodeOrNull("Position")) :: Marker3D).globalTransform
end

return Spawnpoint
