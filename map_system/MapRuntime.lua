local Character = require("../character/Character")
local CameraController = require("../character/CameraController")
local DebugCharacter = require("../debug/menu/DebugCharacter")
local CharacterSpawner = require("CharacterSpawner")

local MapRuntimeImpl = {}
local MapRuntime = gdclass(nil, Node3D)
    :RegisterImpl(MapRuntimeImpl)

type MapRuntimeT = {
    camera: CameraController.CameraController,
    players: Node3D,
    debugCharacter: DebugCharacter.DebugCharacter,

    characterScene: PackedScene,
}

export type MapRuntime = Node3D & MapRuntimeT & typeof(MapRuntimeImpl)

function MapRuntimeImpl._Ready(self: MapRuntime)
    self.camera = self:GetNode("CameraController") :: CameraController.CameraController
    self.players = self:GetNode("Players") :: Node3D
    self.debugCharacter = self:GetNode("HUD/DebugCharacter") :: DebugCharacter.DebugCharacter

    -- Cannot do at load-time due to cyclic dependency :( (character.tscn -> AreaHandler -> MapRuntime -> character.tscn)
    self.characterScene = assert(load("res://character/character.tscn")) :: PackedScene
end

MapRuntime:RegisterMethod("_Ready")

function MapRuntimeImpl.SpawnLocalCharacter(self: MapRuntime, scene: Node)
    local spawner = scene:GetNodeOrNull("CharacterSpawner")
    if spawner and spawner:IsA(CharacterSpawner) then
        local character = (spawner :: CharacterSpawner.CharacterSpawner):SpawnCharacter(self.characterScene, self.camera)

        if character then
            self.players:AddChild(character)

            if character:IsA(Character) then
                self.debugCharacter.characterPath = character:GetPath()
            end
        end
    else
        -- Fallback: Spawn at Vector3.ZERO
        local character = self.characterScene:Instantiate() :: Character.Character
        character.cameraPath = self.camera:GetPath()

        self.players:AddChild(character)
        self.debugCharacter.characterPath = character:GetPath()
    end
end

return MapRuntime
