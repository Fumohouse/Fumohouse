local ConfigBoundControl = require("ConfigBoundControl")

local ConfigButtonImpl = {}
local ConfigButton = gdclass(nil, ConfigBoundControl)
    :RegisterImpl(ConfigButtonImpl)

export type ConfigButton = ConfigBoundControl.ConfigBoundControl & typeof(ConfigButtonImpl) & {
    input: Button,
}

function ConfigButtonImpl._SetValue(self: ConfigButton, value: boolean)
    self.input.buttonPressed = value
end

function ConfigButtonImpl._GetValue(self: ConfigButton): Variant
    return self.input.buttonPressed
end

function ConfigButtonImpl._OnToggled(self: ConfigButton, pressed: boolean)
    self:UpdateConfigValue()
end

ConfigButton:RegisterMethodAST("_OnToggled")

function ConfigButtonImpl._Ready(self: ConfigButton)
    ConfigBoundControl._Ready(self)

    self.input.toggled:Connect(Callable.new(self, "_OnToggled"))
end

return ConfigButton
