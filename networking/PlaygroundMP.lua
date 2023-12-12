local NetworkManagerM = require("NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

--- @class
--- @extends Control
--- @permissions INTERNAL
local PlaygroundMP = {}
local PlaygroundMPC = gdclass(PlaygroundMP)

--- @classType PlaygroundServer
export type PlaygroundMP = Control & typeof(PlaygroundMP) & {}

--- @registerMethod
function PlaygroundMP.serve(self: PlaygroundMP)
    NetworkManager:Serve("playground", 20722, 20, "password")
end

--- @registerMethod
function PlaygroundMP.join(self: PlaygroundMP)
    NetworkManager:Join("127.0.0.1", 20722, "voided_etc", "password")
end

--- @registerMethod
function PlaygroundMP._Ready(self: PlaygroundMP)
    (self:GetNode("%Serve") :: Button).pressed:Connect(Callable.new(self, "serve"));
    (self:GetNode("%Join") :: Button).pressed:Connect(Callable.new(self, "join"))
end

return PlaygroundMPC
