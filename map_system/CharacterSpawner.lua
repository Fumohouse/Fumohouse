--- @class
--- @extends Node3D
local CharacterSpawner = {}
local CharacterSpawnerC = gdclass(CharacterSpawner)

export type CharacterSpawner = Node3D & typeof(CharacterSpawner)

--- @registerMethod
function CharacterSpawner.MakeCharacter(self: CharacterSpawner): Node3D?
    return nil
end

--- @registerMethod
function CharacterSpawner.GetSpawnpoint(self: CharacterSpawner, character: Node3D): Transform3D
    return Transform3D.IDENTITY
end

return CharacterSpawnerC
