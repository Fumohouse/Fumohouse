local ConfigBoundControl = require("ConfigBoundControl")

local ConfigOptionButtonImpl = {}
local ConfigOptionButton = gdclass(nil, ConfigBoundControl)
    :RegisterImpl(ConfigOptionButtonImpl)

export type ConfigOptionButton = ConfigBoundControl.ConfigBoundControl & typeof(ConfigOptionButtonImpl) & {
    input: OptionButton,
}

function ConfigOptionButtonImpl._SetValue(self: ConfigOptionButton, value: number)
    self.input:Select(value)
end

function ConfigOptionButtonImpl._GetValue(self: ConfigOptionButton): Variant
    return self.input.selected
end

function ConfigOptionButtonImpl._OnItemSelected(self: ConfigOptionButton, idx: number)
    self:UpdateConfigValue()
end

ConfigOptionButton:RegisterMethodAST("_OnItemSelected")

function ConfigOptionButtonImpl._Ready(self: ConfigOptionButton)
    ConfigBoundControl._Ready(self)
    self.input.itemSelected:Connect(Callable.new(self, "_OnItemSelected"))
end

return ConfigOptionButton
