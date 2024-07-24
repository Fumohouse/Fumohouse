local Appearance = require("Appearance")

--- @class
--- @extends Node
local Appearances = {}
local AppearancesC = gdclass(Appearances)

export type Appearances = Node & typeof(Appearances) & {
    current: Appearance.Appearance,
}

local defaultAppearance = assert(load("res://resources/character_presets/momiji.tres")) :: Appearance.Appearance

function Appearances._Init(self: Appearances)
    self.current = Appearance.new() :: Appearance.Appearance
    self.current:CopyFrom(defaultAppearance)
end

return AppearancesC
