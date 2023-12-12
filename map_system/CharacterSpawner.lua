local CameraController = require("../character/CameraController")

--- @class
--- @extends Node3D
local CharacterSpawner = {}
local CharacterSpawnerC = gdclass(CharacterSpawner)

--- @classType CharacterSpawner
export type CharacterSpawner = Node3D & typeof(CharacterSpawner)

--- @registerMethod
function CharacterSpawner.SpawnCharacter(self: CharacterSpawner, camera: CameraController.CameraController): Node3D?
    return nil
end

return CharacterSpawnerC
