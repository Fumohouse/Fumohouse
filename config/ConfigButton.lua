local ConfigBoundControl = require("ConfigBoundControl")

--- @class
--- @extends ConfigBoundControl
local ConfigButton = {}
local ConfigButtonC = gdclass(ConfigButton)

export type ConfigButton = ConfigBoundControl.ConfigBoundControl & typeof(ConfigButton) & {
    input: Button,
}

function ConfigButton._SetValue(self: ConfigButton, value: boolean)
    self.input.buttonPressed = value
end

function ConfigButton._GetValue(self: ConfigButton): Variant
    return self.input.buttonPressed
end

--- @registerMethod
function ConfigButton._OnToggled(self: ConfigButton, pressed: boolean)
    self:UpdateConfigValue()
end

function ConfigButton._Ready(self: ConfigButton)
    ConfigBoundControl._Ready(self)

    self.input.toggled:Connect(Callable.new(self, "_OnToggled"))
end

return ConfigButtonC
