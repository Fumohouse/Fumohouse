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
    scene: Node,
    players: Node3D,

    camera: CameraController.CameraController,
    debugCharacter: DebugCharacter.DebugCharacter,

    characterScene: PackedScene,
}

--- @registerMethod
function MapRuntime._Ready(self: MapRuntime)
    self.scene = assert(self:GetParent())
    self.players = self:GetNode("Players") :: Node3D

    self.camera = self:GetNode("CameraController") :: CameraController.CameraController
    self.debugCharacter = self:GetNode("HUD/DebugMenus/DebugCharacter") :: DebugCharacter.DebugCharacter
end

function MapRuntime.SpawnLocalCharacter(self: MapRuntime)
    local spawner = self.scene:GetNodeOrNull("CharacterSpawner")
    if spawner and spawner:IsA(CharacterSpawner) then
        local character = (spawner :: CharacterSpawner.CharacterSpawner):SpawnCharacter(self.camera)

        if character then
            self.players:AddChild(character)

            if character:IsA(Character) then
                self.debugCharacter.character = character :: Character.Character
            end
        end
    end
end

return MapRuntimeC
