--- @class
--- @extends Node
--- @permissions INTERNAL
local EngineInit = {}
local EngineInitC = gdclass(EngineInit)

export type EngineInit = Node & typeof(EngineInit)

--- @registerMethod
function EngineInit._Ready(self: EngineInit)
    -- Initialize at earliest point after init.lua (SceneTree not available earlier)
    LuauInterface.SandboxService:ProtectedObjectAdd(self:GetTree().root, Enum.Permissions.INTERNAL)
end

return EngineInitC
