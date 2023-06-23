local MapManagerM = require("MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

--- @class
--- @extends Node3D
--- @permissions INTERNAL
local PlaygroundLoader = {}
local PlaygroundLoaderC = gdclass(PlaygroundLoader)

--- @classType PlaygroundLoader
export type PlaygroundLoader = Node3D & typeof(PlaygroundLoader)

--- @registerMethod
function PlaygroundLoader.switch(self: PlaygroundLoader)
    MapManager:Load("playground")
end

--- @registerMethod
function PlaygroundLoader._Ready(self: PlaygroundLoader)
    Callable.new(self, "switch"):CallDeferred()
end

return PlaygroundLoaderC
