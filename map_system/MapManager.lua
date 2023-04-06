local MapManifest = require("MapManifest")
local MapRuntime = require("MapRuntime")

local MusicPlayerM = require("../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MapManagerImpl = {}
local MapManager = gdclass(nil, Node)
    :Permissions(bit32.bor(Enum.Permissions.FILE, Enum.Permissions.INTERNAL))
    :RegisterImpl(MapManagerImpl)

export type MapManager = Node & typeof(MapManagerImpl) & {
    maps: {MapManifest.MapManifest},
    currentMap: MapManifest.MapManifest?,
    currentRuntime: MapRuntime.MapRuntime?,
    runtimeScene: PackedScene,
}

local BASE_DIR = "res://maps/"

function MapManagerImpl._Init(self: MapManager)
    self.maps = {}

    -- Done in _Init to avoid cyclic dependency
    self.runtimeScene = assert(load("res://map_system/runtime.tscn")) :: PackedScene
end

function MapManagerImpl._Ready(self: MapManager)
    local dir = DirAccess.Open(BASE_DIR)
    assert(dir, "Failed to open maps directory")

    dir:ListDirBegin()

    local fileName = dir:GetNext()

    while fileName ~= "" do
        if dir:CurrentIsDir() then
            local mapDir = BASE_DIR .. fileName .. "/"
            local manifestPath = mapDir .. "manifest.tres"

            local manifest = load(manifestPath) :: Resource?

            if manifest and manifest:IsA(MapManifest) then
                table.insert(self.maps, manifest :: MapManifest.MapManifest)
            else
                push_warning(`Manifest at {manifestPath} is invalid or doesn't exist.`)
            end
        end

        fileName = dir:GetNext()
    end
end

MapManager:RegisterMethod("_Ready")

function MapManagerImpl.loadInternal(self: MapManager, manifest: MapManifest.MapManifest)
    local scene = load(manifest.mainScenePath) :: Resource?
    if not scene or not scene:IsA(PackedScene) then
        error(`Failed to load main scene at {manifest.mainScenePath}.`)
    end

    MusicPlayer:LoadPlaylists(manifest.playlists)

    -- Switch scenes manually (otherwise switch is deferred to next frame)
    local newScene = (scene :: PackedScene):Instantiate()
    self:GetTree():GetRoot():AddChild(newScene)

    local runtime = self.runtimeScene:Instantiate() :: MapRuntime.MapRuntime
    self.currentMap = manifest
    self.currentRuntime = runtime

    newScene:AddChild(runtime)
    newScene:MoveChild(runtime, 0)
    runtime:SpawnLocalCharacter(newScene)

    local currentScene = self:GetTree():GetCurrentScene()
    if currentScene then
        currentScene:QueueFree()
    end

    self:GetTree():SetCurrentScene(newScene)
end

function MapManagerImpl.Load(self: MapManager, id: string)
    for _, map in self.maps do
        if map.id == id then
            self:loadInternal(map)
            return
        end
    end
end

return MapManager
