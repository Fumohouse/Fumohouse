local MotionState = require("../MotionState.mod")

local MusicPlayerM = require("../../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MapManagerM = require("../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local NetworkManagerM = require("../../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

local AreaHandler = { ID = "areaHandler" }
AreaHandler.__index = AreaHandler

function AreaHandler.new()
    local self = {}
    return setmetatable(self, AreaHandler)
end

function AreaHandler.Process(self: AreaHandler, state: MotionState.MotionState, delta: number)
    if NetworkManager.isActive and state.peer ~= 1 then
        return
    end

    local currentMap = assert(MapManager.currentMap).manifest

    for _, area in state.intersections.areas do
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
