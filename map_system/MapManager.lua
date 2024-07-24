local MapManifest = require("MapManifest")
local MapRuntime = require("MapRuntime")
local MainMenu = require("../ui/navigation/main_menu/MainMenu")

local MusicPlayerM = require("../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local AppearancesM = require("../character/appearance/Appearances")
local Appearances = gdglobal("Appearances") :: AppearancesM.Appearances

local NetworkManagerM = require("../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

local ConfigManagerM = require("../config/ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class
--- @extends Node
--- @permissions FILE
local MapManager = {}
local MapManagerC = gdclass(MapManager)

export type MapData = {
    manifest: MapManifest.MapManifest,
    hash: string,
}

export type MapManager = Node & typeof(MapManager) & {
    --- @signal
    statusUpdate: SignalWithArgs<(details: string, failure: boolean) -> ()>,

    --- @signal
    mapChanged: SignalWithArgs<(manifest: MapManifest.MapManifest?) -> ()>,

    maps: {[string]: MapData},
    currentMap: MapData?,
    currentRuntime: MapRuntime.MapRuntime?,
    runtimeScene: PackedScene,
}

local BASE_DIR = "res://maps/"

function MapManager._Init(self: MapManager)
    self.maps = {}

    -- Done in _Init to avoid cyclic dependency
    self.runtimeScene = assert(load("res://map_system/runtime.tscn")) :: PackedScene
end

--- @registerMethod
function MapManager._Ready(self: MapManager)
    local dir = DirAccess.Open(BASE_DIR)
    assert(dir, "Failed to open maps directory")

    dir:ListDirBegin()

    local fileName = dir:GetNext()

    while fileName ~= "" do
        if dir:CurrentIsDir() then
            local mapDir = BASE_DIR .. fileName .. "/"
            local manifestPath = mapDir .. "manifest.tres"

            local res = load(manifestPath) :: Resource?

            if res and res:IsA(MapManifest) then
                local manifest = res :: MapManifest.MapManifest

                self.maps[manifest.id] = {
                    manifest = manifest,
                    hash = "",
                }
            else
                push_warning(`Manifest at {manifestPath} is invalid or doesn't exist.`)
            end
        end

        fileName = dir:GetNext()
    end
end

function MapManager.sendStatusUpdate(self: MapManager, details: string, failure: boolean?)
    self.statusUpdate:Emit(details, failure or false)
    for i = 1, 2 do
        wait_signal(self:GetTree().processFrame)
    end
end

function MapManager.Load(self: MapManager, id: string)
    local map = self.maps[id]
    if not map then
        return
    end

    self:sendStatusUpdate("Loading map...")

    local scene = load(map.manifest.mainScenePath) :: Resource?
    if not scene or not scene:IsA(PackedScene) then
        error(`Failed to load main scene at {map.manifest.mainScenePath}.`)
    end

    MusicPlayer:LoadPlaylists(map.manifest.playlists)

    -- Switch scenes manually (otherwise switch is deferred to next frame)
    local newScene = (scene :: PackedScene):Instantiate()
    self:GetTree().root:AddChild(newScene)

    local runtime = self.runtimeScene:Instantiate() :: MapRuntime.MapRuntime
    self.currentMap = map
    self.currentRuntime = runtime

    newScene:AddChild(runtime)
    newScene:MoveChild(runtime, 0)

    local currentScene = self:GetTree().currentScene
    if currentScene then
        currentScene:QueueFree()
    end

    self:GetTree().currentScene = newScene

    self.mapChanged:Emit(map.manifest)
end

function MapManager.StartSingleplayer(self: MapManager, id: string)
    self:Load(id)
    assert(self.currentRuntime).players:SpawnCharacter(Appearances.current)
end

function MapManager.StartMultiplayerServer(self: MapManager, id: string)
    local port = ConfigManager:Get("multiplayer/server/port") :: number
    local maxClients = ConfigManager:Get("multiplayer/server/maxClients") :: number
    local password = ConfigManager:Get("multiplayer/server/password") :: string

    NetworkManager:Serve(id, port, maxClients, password)
end

--- @registerMethod
function MapManager._OnLeaveTransitionFinished(self: MapManager, prevScene: Node)
    if prevScene then
        prevScene:QueueFree()
    end
end

function MapManager.Leave(self: MapManager)
    self.currentMap = nil
    self.currentRuntime = nil

    if NetworkManager.isActive then
        if NetworkManager.isServer then
            NetworkManager:CloseServer()
        else
            NetworkManager:DisconnectWithReason(1, "Disconnected")
        end
    end

    self:sendStatusUpdate("Loading main scene...")

    local mainScene: PackedScene = assert(load("res://ui/navigation/main_menu/main_menu.tscn"))

    local mainMenu = mainScene:Instantiate() :: MainMenu.MainMenu
    mainMenu.transitionIn = false
    self:GetTree().root:AddChild(mainMenu)

    local currentScene = self:GetTree().currentScene
    self:GetTree().currentScene = mainMenu

    mainMenu.modulate = Color.TRANSPARENT

    local tween = self:CreateTween()
    tween:TweenProperty(mainMenu, "modulate", Color.WHITE, 0.6)
    tween:TweenCallback(Callable.new(self, "_OnLeaveTransitionFinished"):Bind(currentScene))
    mainMenu:Dim(false)

    self:PlayTitlePlaylist()

    mainMenu:SetScreen(mainMenu.playScreen)
end

function MapManager.GetTitleMap(self: MapManager)
    local DEFAULT_MAP = "fumohouse"

    local map = self.maps[DEFAULT_MAP]
    if not map then
        local _, firstMap = next(self.maps)
        map = firstMap
    end

    return map
end

function MapManager.PlayTitlePlaylist(self: MapManager)
    local menuMap = self:GetTitleMap().manifest

    MusicPlayer:LoadPlaylists(menuMap.playlists)
    MusicPlayer:SwitchPlaylist(menuMap.titlePlaylist)
end

return MapManagerC
