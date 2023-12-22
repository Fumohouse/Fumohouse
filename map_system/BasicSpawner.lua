local CharacterSpawner = require("CharacterSpawner")
local Character = require("../character/Character")
local Spawnpoint = require("Spawnpoint")

--- @class BasicSpawner
--- @extends CharacterSpawner
local BasicSpawner = {}
local BasicSpawnerC = gdclass(BasicSpawner)

--- @classType BasicSpawner
export type BasicSpawner = CharacterSpawner.CharacterSpawner

local characterScene = assert(load("res://character/character.tscn")) :: PackedScene

--- @registerMethod
function BasicSpawner.MakeCharacter(self: BasicSpawner): Node3D?
    return characterScene:Instantiate() :: Character.Character
end

function BasicSpawner.GetSpawnpoint(self: BasicSpawner, character: Node3D): Transform3D
    local children = self:GetChildren()
    local spawnpoint = children:Get(math.random(0, children:Size() - 1)) :: Node

    if spawnpoint:IsA(Spawnpoint) then
        return (spawnpoint :: Spawnpoint.Spawnpoint):GetSpawnPoint()
    end

    return Transform3D.IDENTITY
end

return BasicSpawnerC
