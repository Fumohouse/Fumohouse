local Character = require("Character")

local MusicPlayerM = require("../music/MusicPlayer")
local MusicPlayer = gdglobal("MusicPlayer") :: MusicPlayerM.MusicPlayer

local MapManagerM = require("../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local AreaHandlerImpl = {}
local AreaHandler = gdclass(nil, Node)
    :RegisterImpl(AreaHandlerImpl)

type AreaHandlerT = {
    character: Character.Character,
}

export type AreaHandler = Node & AreaHandlerT & typeof(AreaHandlerImpl)

function AreaHandlerImpl._Ready(self: AreaHandler)
    self.character = assert(self:GetParent()) :: Character.Character
end

AreaHandler:RegisterMethod("_Ready")

function AreaHandlerImpl._Process(self: AreaHandler, delta: number)
    local collideParams = PhysicsShapeQueryParameters3D.new()
    collideParams.shape = self.character.capsule
    collideParams.transform = self.character.collider.globalTransform
    collideParams.collideWithAreas = true
    collideParams.collideWithBodies = false

    local result = self.character:GetWorld3D().directSpaceState:IntersectShape(collideParams)
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

AreaHandler:RegisterMethodAST("_Process")

return AreaHandler
