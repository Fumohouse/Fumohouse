local ConfigBoundControl = require("ConfigBoundControl")

--- @class
--- @extends ConfigBoundControl
local ConfigOptionButton = {}
local ConfigOptionButtonC = gdclass(ConfigOptionButton)

--- @classType ConfigOptionButton
export type ConfigOptionButton = ConfigBoundControl.ConfigBoundControl & typeof(ConfigOptionButton) & {
    input: OptionButton,
}

function ConfigOptionButton._SetValue(self: ConfigOptionButton, value: number)
    self.input:Select(value)
end

function ConfigOptionButton._GetValue(self: ConfigOptionButton): Variant
    return self.input.selected
end

--- @registerMethod
function ConfigOptionButton._OnItemSelected(self: ConfigOptionButton, idx: number)
    self:UpdateConfigValue()
end

function ConfigOptionButton._Ready(self: ConfigOptionButton)
    ConfigBoundControl._Ready(self)
    self.input.itemSelected:Connect(Callable.new(self, "_OnItemSelected"))
end

return ConfigOptionButtonC
