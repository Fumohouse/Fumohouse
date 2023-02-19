local MapManagerM = require("MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local PlaygroundLoaderImpl = {}
local PlaygroundLoader = gdclass(nil, Node3D)
    :Permissions(Enum.Permissions.INTERNAL)
    :RegisterImpl(PlaygroundLoaderImpl)

export type PlaygroundLoader = Node3D & typeof(PlaygroundLoaderImpl)

function PlaygroundLoaderImpl.switch(self: PlaygroundLoader)
    MapManager:Load("playground")
end

PlaygroundLoader:RegisterMethod("switch")

function PlaygroundLoaderImpl._Ready(self: PlaygroundLoader)
    Callable.new(self, "switch"):CallDeferred()
end

PlaygroundLoader:RegisterMethod("_Ready")

return PlaygroundLoader
