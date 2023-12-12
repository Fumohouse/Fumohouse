local CharacterSpawner = require("CharacterSpawner")
local CameraController = require("../character/CameraController")
local Character = require("../character/Character")
local Spawnpoint = require("Spawnpoint")

--- @class BasicSpawner
--- @extends CharacterSpawner
local BasicSpawner = {}
local BasicSpawnerC = gdclass(BasicSpawner)

--- @classType BasicSpawner
export type BasicSpawner = CharacterSpawner.CharacterSpawner

local characterScene = assert(load("res://character/character.tscn")) :: PackedScene

function BasicSpawner.SpawnCharacter(self: BasicSpawner, camera: CameraController.CameraController): Node3D?
    local character = characterScene:Instantiate() :: Character.Character
    character.camera = camera

    local children = self:GetChildren()
    local spawnpoint = children:Get(math.random(1, children:Size())) :: Node

    if spawnpoint:IsA(Spawnpoint) then
        character.transform = (spawnpoint :: Spawnpoint.Spawnpoint):GetSpawnPoint()
    end

    return character
end

return BasicSpawnerC
