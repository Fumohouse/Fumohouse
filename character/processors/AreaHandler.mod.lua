local MotionState = require("../MotionState.mod")

local MusicPlayerM = require("../../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MapManagerM = require("../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local AreaHandler = setmetatable({
    ID = "areaHandler",
}, MotionState.MotionProcessor)

AreaHandler.__index = AreaHandler

function AreaHandler.new()
    local self = {}
    return setmetatable(self, AreaHandler)
end

function AreaHandler.Process(self: AreaHandler, state: MotionState.MotionState, delta: number)
    local collideParams = PhysicsShapeQueryParameters3D.new()
    collideParams.shape = state.mainCollisionShape
    collideParams.transform = state.mainCollider.globalTransform
    collideParams.collideWithAreas = true
    collideParams.collideWithBodies = false

    local result = state.GetWorld3D().directSpaceState:IntersectShape(collideParams)
    local currentMap = assert(MapManager.currentMap)

    for _, data: Dictionary in result do
        local area = data:Get("collider") :: Area3D
        if not area:HasMeta("playlist") then
            continue
        end

        local playlist = area:GetMeta("playlist")
        assert(typeof(playlist) == "string")

        if playlist == "" then
            MusicPlayer:SwitchPlaylist(currentMap.defaultPlaylist)
        else
            MusicPlayer:SwitchPlaylist(playlist)
        end

        return
    end

    MusicPlayer:SwitchPlaylist(currentMap.defaultPlaylist)
end

export type AreaHandler = typeof(AreaHandler.new())
return AreaHandler
