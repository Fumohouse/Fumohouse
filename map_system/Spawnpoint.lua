--- @class Spawnpoint
--- @extends Node3D
local Spawnpoint = {}
local SpawnpointC = gdclass(Spawnpoint)

--- @classType Spawnpoint
export type Spawnpoint = Node3D & typeof(Spawnpoint)

--- @registerMethod
function Spawnpoint.GetSpawnPoint(self: Spawnpoint): Transform3D
    return (self:GetNode("Position") :: Marker3D).globalTransform
end

return SpawnpointC
