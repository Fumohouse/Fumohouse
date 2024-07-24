--- @class
--- @extends Control
--- @tool
local Dock = {}
local DockC = gdclass(Dock)

export type Dock = Control & typeof(Dock) & {
    plugin: EditorPlugin,
}

return DockC
