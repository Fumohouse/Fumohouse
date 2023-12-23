local Character = require("../character/Character")
local CharacterSpawner = require("CharacterSpawner")
local DebugCharacter = require("../ui/debug/DebugCharacter")
local CameraController = require("../character/CameraController")
local Appearance = require("../character/appearance/Appearance")
local AppearanceManager = require("../character/appearance/AppearanceManager")
local Utils = require("../utils/Utils.mod")

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
    nextId: number,

    -- DI
    scene: Node,
}

function CharacterManager._Init(self: CharacterManager)
    self.characters = {}
    self.nextId = 1
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
            local appearanceManager = c:GetNode("Appearance") :: AppearanceManager.AppearanceManager
            appearanceManager.appearance = appearance
        end

        if not peer then
            c.camera = self.camera
        end
    end

    if peer then
        if self.characters[peer] then
            self.characters[peer]:QueueFree()
        end

        character.name = NetworkManager.peerData[peer].identity
        self.characters[peer] = character
    else
        if self.localCharacter then
            self.localCharacter:QueueFree()
        end

        if NetworkManager.isActive then
            character.name = NetworkManager.identity
        end

        self.localCharacter = character
    end

    self:AddChild(character)
    if character:IsA(Character) then
        self.debugCharacter.character = character :: Character.Character
    end

    if NetworkManager.isServer then
        local state = CharacterStatePacket.server.new(CharacterStatePacket.CharacterStateUpdateType.SPAWN, peer)

        if appearance then
            state.appearance = appearance
        end
        state.transform = character.globalTransform

        NetworkManager:SendPacket(0, state)
    end

    return character
end

function CharacterManager.GetCharacter(self: CharacterManager, peer: number)
    local character: Node3D?

    if not NetworkManager.isActive or peer == NetworkManager.peer:GetUniqueId() then
        character = self.localCharacter
    else
        character = self.characters[peer]
    end

    return character
end

local DEATH_TIMEOUT = 5

function CharacterManager.DeleteCharacter(self: CharacterManager, peer: number, died: boolean?, callback: (() -> ())?)
    local character = self:GetCharacter(peer)
    if character then
        if died and character:IsA(Character) then
            local c = character :: Character.Character

            if c.state:IsDead() then
                return
            end

            c.state:Die(DEATH_TIMEOUT, function()
                if callback then
                    callback()
                end

                if character == self.localCharacter then
                    self.localCharacter = nil
                elseif character == self.characters[peer] then
                    self.characters[peer] = nil
                end
            end)
        else
            character:QueueFree()

            if character == self.localCharacter then
                self.localCharacter = nil
            else
                self.characters[peer] = nil
            end
        end

        if NetworkManager.isServer then
            local state = CharacterStatePacket.server.new(CharacterStatePacket.CharacterStateUpdateType.DELETE, peer)
            state.died = died or false

            NetworkManager:SendPacket(0, state)
        end
    end
end

function CharacterManager.UpdateAppearance(self: CharacterManager, peer: number, appearance: Appearance.Appearance)
    local character = self.characters[peer]
    if character and character:IsA(Character) then
        local appearanceManager = (character:GetNode("Appearance") :: AppearanceManager.AppearanceManager)

        appearanceManager.appearance = appearance
        appearanceManager:LoadAppearance()
    end
end

function CharacterManager.SendSyncPacket(self: CharacterManager, peer: number)
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
            appearances[i] = (character:GetNode("Appearance") :: AppearanceManager.AppearanceManager).appearance
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

local function getAppearance(character: Node3D): Appearance.Appearance?
    if character:IsA(Character) then
        return ((character :: Character.Character):GetNode("Appearance") :: AppearanceManager.AppearanceManager).appearance
    else
        return nil
    end
end

--- @registerMethod
function CharacterManager._Process(self: CharacterManager, delta: number)
    local FALL_LIMIT = -64

    if self.localCharacter and Utils.DoGameInput(self) and Input.singleton:IsActionJustPressed("reset_character") then
        local appearance = getAppearance(self.localCharacter)

        if NetworkManager.isActive then
            if NetworkManager.isServer then
                return
            end

            local req = CharacterRequestPacket.client.new(CharacterStatePacket.CharacterStateUpdateType.DELETE)
            req.died = true

            NetworkManager:SendPacket(1, req)

            wait(DEATH_TIMEOUT + 1)

            local req2 = CharacterRequestPacket.client.new(CharacterStatePacket.CharacterStateUpdateType.SPAWN)
            req2.appearance = appearance

            NetworkManager:SendPacket(1, req2)
        else
            self:DeleteCharacter(0, true, function()
                self:SpawnCharacter(appearance)
            end)
        end
    end

    if NetworkManager.isActive then
        if not NetworkManager.isServer then
            return
        end

        for peer, character in self.characters do
            if character.position.y < FALL_LIMIT then
                local appearance = getAppearance(character)

                self:DeleteCharacter(peer, true, function()
                    self:SpawnCharacter(appearance, peer)
                end)
            end
        end
    else
        if self.localCharacter and self.localCharacter.position.y < FALL_LIMIT then
            local appearance = getAppearance(self.localCharacter)

            self:DeleteCharacter(0, true, function()
                self:SpawnCharacter(appearance)
            end)
        end
    end
end

return CharacterManagerC
