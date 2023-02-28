local CharacterSpawner = require("CharacterSpawner")
local CameraController = require("../character/CameraController")
local Character = require("../character/Character")
local Spawnpoint = require("Spawnpoint")

local BasicSpawnerImpl = {}
local BasicSpawner = gdclass("BasicSpawner", CharacterSpawner)
    :RegisterImpl(BasicSpawnerImpl)

export type BasicSpawner = CharacterSpawner.CharacterSpawner

function BasicSpawnerImpl.SpawnCharacter(self: BasicSpawner, defaultScene: PackedScene, camera: CameraController.CameraController): Node3D?
    local character = defaultScene:Instantiate() :: Character.Character
    character.cameraPath = camera:GetPath()

    local children = self:GetChildren()
    local spawnpoint = children:Get(math.random(1, children:Size())) :: Node

    if spawnpoint:IsA(Spawnpoint) then
        character.transform = (spawnpoint :: Spawnpoint.Spawnpoint):GetSpawnPoint()
    end

    return character
end

return BasicSpawner
