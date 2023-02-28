local MapManifest = require("MapManifest")
local MapRuntime = require("MapRuntime")

local MusicPlayerM = require("../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MapManagerImpl = {}
local MapManager = gdclass(nil, Node)
    :Permissions(bit32.bor(Enum.Permissions.FILE, Enum.Permissions.INTERNAL))
    :RegisterImpl(MapManagerImpl)

type MapManagerT = {
    maps: {MapManifest.MapManifest},
    currentMap: MapManifest.MapManifest?,
}

export type MapManager = Node & MapManagerT & typeof(MapManagerImpl)

local BASE_DIR = "res://maps/"
local runtimeScene = assert(load("res://map_system/runtime.tscn")) :: PackedScene

function MapManagerImpl._Init(obj: Node, tbl: MapManagerT)
    tbl.maps = {}
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
    if scene and scene:IsA(PackedScene) then
        MusicPlayer:LoadPlaylists(manifest.playlists)

        -- Switch scenes manually (otherwise switch is deferred to next frame)
        local newScene = (scene :: PackedScene):Instantiate()
        self:GetTree():GetRoot():AddChild(newScene)

        local runtime = runtimeScene:Instantiate() :: MapRuntime.MapRuntime
        newScene:AddChild(runtime)
        runtime:SpawnLocalCharacter(newScene)

        local currentScene = self:GetTree():GetCurrentScene()
        if currentScene then
            currentScene:QueueFree()
        end

        self:GetTree():SetCurrentScene(newScene)
        self.currentMap = manifest
    else
        error(`Failed to load main scene at {manifest.mainScenePath}.`)
    end
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
