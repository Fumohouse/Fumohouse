local Character = require("../character/Character")
local CameraController = require("../character/CameraController")
local DebugCharacter = require("../ui/debug/DebugCharacter")
local CharacterSpawner = require("CharacterSpawner")

--- @class
--- @extends Node3D
local MapRuntime = {}
local MapRuntimeC = gdclass(MapRuntime)

--- @classType MapRuntime
export type MapRuntime = Node3D & typeof(MapRuntime) & {
    camera: CameraController.CameraController,
    players: Node3D,
    debugCharacter: DebugCharacter.DebugCharacter,

    characterScene: PackedScene,
}

--- @registerMethod
function MapRuntime._Ready(self: MapRuntime)
    self.camera = self:GetNode("CameraController") :: CameraController.CameraController
    self.players = self:GetNode("Players") :: Node3D
    self.debugCharacter = self:GetNode("HUD/DebugMenus/DebugCharacter") :: DebugCharacter.DebugCharacter

    -- Cannot do at load-time due to cyclic dependency :( (character.tscn -> AreaHandler -> MapRuntime -> character.tscn)
    self.characterScene = assert(load("res://character/character.tscn")) :: PackedScene
end

function MapRuntime.SpawnLocalCharacter(self: MapRuntime, scene: Node)
    local spawner = scene:GetNodeOrNull("CharacterSpawner")
    if spawner and spawner:IsA(CharacterSpawner) then
        local character = (spawner :: CharacterSpawner.CharacterSpawner):SpawnCharacter(self.characterScene, self.camera)

        if character then
            self.players:AddChild(character)

            if character:IsA(Character) then
                self.debugCharacter.character = character :: Character.Character
            end
        end
    else
        -- Fallback: Spawn at Vector3.ZERO
        local character = self.characterScene:Instantiate() :: Character.Character
        character.camera = self.camera

        self.players:AddChild(character)
        self.debugCharacter.character = character
    end
end

return MapRuntimeC
