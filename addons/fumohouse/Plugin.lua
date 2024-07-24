local Dock = require("Dock")

--- @class
--- @extends EditorPlugin
--- @tool
local Plugin = {}
local PluginC = gdclass(Plugin)

export type Plugin = EditorPlugin & typeof(Plugin) & {
    dock: Dock.Dock,
}

--- @registerMethod
function Plugin._EnterTree(self: Plugin)
    self.dock = (assert(load("dock.tscn")) :: PackedScene):Instantiate() :: Dock.Dock
    self.dock.plugin = self
    self:AddControlToDock(EditorPlugin.DockSlot.RIGHT_UL, self.dock)
end

--- @registerMethod
function Plugin._ExitTree(self: Plugin)
    self:RemoveControlFromDocks(self.dock)
    self.dock:Free()
end

return PluginC
