local Character = require("../character/Character")
local CharacterSpawner = require("CharacterSpawner")
local DebugCharacter = require("../ui/debug/DebugCharacter")
local CameraController = require("../character/CameraController")
local Appearance = require("../character/appearance/Appearance")
local AppearanceManager = require("../character/appearance/AppearanceManager")

local NetworkManagerM = require("../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

local CharacterSyncPacket = require("../networking/packets/runtime/CharacterSyncPacket.mod")
local CharacterRequestPacket = require("../networking/packets/runtime/CharacterRequestPacket.mod")
local CharacterStatePacket = require("../networking/packets/runtime/CharacterStatePacket.mod")

--- @class
--- @extends Node3D
local CharacterManager = {}
local CharacterManagerC = gdclass(CharacterManager)

--- @classType CharacterManager
export type CharacterManager = Node3D & typeof(CharacterManager) & {
    --- @property
    debugCharacter: DebugCharacter.DebugCharacter,
    --- @property
    camera: CameraController.CameraController,

    localCharacter: Node3D?,
    characters: {[number]: Node3D},

    -- DI
    scene: Node,
}

function CharacterManager._Init(self: CharacterManager)
    self.characters = {}
end

function CharacterManager.SpawnCharacter(self: CharacterManager, appearance: Appearance.Appearance?, peer: number?, transform: Transform3D?): Node3D?
    local spawner = self.scene:GetNodeOrNull("CharacterSpawner")
    if not spawner or not spawner:IsA(CharacterSpawner) then
        return nil
    end

    local sp = spawner :: CharacterSpawner.CharacterSpawner

    local character = sp:MakeCharacter()
    if not character then
        return nil
    end

    if transform then
        character.globalTransform = transform
    else
        character.globalTransform = sp:GetSpawnpoint(character)
    end

    if character:IsA(Character) then
        local c = character :: Character.Character

        if NetworkManager.isActive then
            c.peer = peer or 1
        end

        if appearance then
            local appearanceManager = c:GetNode("%Appearance") :: AppearanceManager.AppearanceManager
            appearanceManager.appearance = appearance
        end

        if not peer then
            c.camera = self.camera
            self.debugCharacter.character = c
        end
    end

    if peer then
        if self.characters[peer] then
            self.characters[peer]:QueueFree()
        end

        self.characters[peer] = character
    else
        if self.localCharacter then
            self.localCharacter:QueueFree()
        end

        self.localCharacter = character
    end

    self:AddChild(character)
    return character
end

function CharacterManager.GetCharacter(self: CharacterManager, peer: number)
    local character: Node3D?

    if peer == NetworkManager.peer:GetUniqueId() then
        character = self.localCharacter
    else
        character = self.characters[peer]
    end

    return character
end

function CharacterManager.DeleteCharacter(self: CharacterManager, peer: number, died: boolean?)
    local character = self:GetCharacter(peer)
    if character then
        -- TODO: handle death animation
        if not died then
            character:QueueFree()
        end

        self.characters[peer] = nil
    end
end

function CharacterManager.UpdateAppearance(self: CharacterManager, peer: number, appearance: Appearance.Appearance)
    local character = self.characters[peer]
    if character and character:IsA(Character) then
        local appearanceManager = (character:GetNode("%Appearance") :: AppearanceManager.AppearanceManager)

        appearanceManager.appearance = appearance
        appearanceManager:LoadAppearance()
    end
end

function CharacterManager.SendSyncPacket(self: CharacterManager, peer: number)
    assert(NetworkManager.isServer)

    local sync = CharacterSyncPacket.server.new()

    local peers = sync.peers
    local transforms = sync.transforms
    local states = sync.states
    local isRagdoll = sync.isRagdoll
    local appearances = sync.appearances

    for remotePeer, character in self.characters do
        if remotePeer == peer then
            continue
        end

        local i = #peers + 1

        peers[i] = remotePeer
        transforms[i] = character.transform
        if character:IsA(Character) then
            local c = character :: Character.Character

            states[i] = c.state.state
            isRagdoll[i] = c.state.isRagdoll
            appearances[i] = (character:GetNode("%Appearance") :: AppearanceManager.AppearanceManager).appearance
        end
    end

    sync.count = #peers

    NetworkManager:SendPacket(peer, sync)
end

function CharacterManager.ProcessMovementRequest(self: CharacterManager, peer: number, packet: CharacterRequestPacket.CharacterRequestPacket)
    local character = self.characters[peer]
    if not character or not character:IsA(Character) then
        return
    end

    (character :: Character.Character):ProcessMovementRequest(packet)
end

function CharacterManager.ProcessMovementUpdate(self: CharacterManager, packet: CharacterStatePacket.CharacterStatePacket)
    local character = self:GetCharacter(packet.peer)
    if not character or not character:IsA(Character) then
        return
    end

    (character :: Character.Character):ProcessMovementUpdate(packet)
end

return CharacterManagerC
