local MapManifest = require("MapManifest")
local MapRuntime = require("MapRuntime")

local MusicPlayerM = require("../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

--- @class
--- @extends Node
--- @permissions FILE
local MapManager = {}
local MapManagerC = gdclass(MapManager)

export type MapData = {
    manifest: MapManifest.MapManifest,
    hash: string,
}

--- @classType MapManager
export type MapManager = Node & typeof(MapManager) & {
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

function MapManager.Load(self: MapManager, id: string)
    local map = self.maps[id]
    if not map then
        return
    end

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

    local currentScene = self:GetTree():GetCurrentScene()
    if currentScene then
        currentScene:QueueFree()
    end

    self:GetTree():SetCurrentScene(newScene)
end

function MapManager.getTitleMap(self: MapManager)
    local DEFAULT_MAP = "fumohouse"

    local map = self.maps[DEFAULT_MAP]
    if not map then
        local _, firstMap = next(self.maps)
        map = firstMap
    end

    return map
end

function MapManager.PlayTitlePlaylist(self: MapManager)
    local menuMap = self:getTitleMap().manifest

    MusicPlayer:LoadPlaylists(menuMap.playlists)
    MusicPlayer:SwitchPlaylist(menuMap.titlePlaylist)
end

return MapManagerC
