local CharacterManager = require("CharacterManager")

--- @class
--- @extends Node3D
local MapRuntime = {}
local MapRuntimeC = gdclass(MapRuntime)

export type MapRuntime = Node3D & typeof(MapRuntime) & {
    --- @property
    players: CharacterManager.CharacterManager,

    scene: Node,
}

--- @registerMethod
function MapRuntime._Ready(self: MapRuntime)
    self.scene = assert(self:GetParent())

    -- DI
    self.players.scene = self.scene
end

return MapRuntimeC
