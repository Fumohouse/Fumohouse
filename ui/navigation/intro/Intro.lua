local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

--- @class
--- @extends Control
--- @permissions INTERNAL
local Intro = {}
local IntroC = gdclass(Intro)

export type Intro = Control & typeof(Intro) & {
    --- @property
    postScene: PackedScene,
}

--- @registerMethod
function Intro.PlayMusic(self: Intro)
    MapManager:PlayTitlePlaylist()
end

--- @registerMethod
function Intro.IntroEnded(self: Intro)
    self:GetTree():ChangeSceneToPacked(self.postScene)
end

return IntroC
