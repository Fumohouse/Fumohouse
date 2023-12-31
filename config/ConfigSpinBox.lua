local ConfigBoundControl = require("ConfigBoundControl")

--- @class
--- @extends ConfigBoundControl
local ConfigSpinBox = {}
local ConfigSpinBoxC = gdclass(ConfigSpinBox)

--- @classType ConfigSpinBox
export type ConfigSpinBox = ConfigBoundControl.ConfigBoundControl & typeof(ConfigSpinBox) & {
    input: SpinBox,
}

function ConfigSpinBox._SetValue(self: ConfigSpinBox, value: number)
    self.input.value = value
end

function ConfigSpinBox._GetValue(self: ConfigSpinBox): Variant
    return self.input.value
end

--- @registerMethod
function ConfigSpinBox._OnValueChanged(self: ConfigSpinBox, value: number)
    self:UpdateConfigValue()
end

function ConfigSpinBox._Ready(self: ConfigSpinBox)
    ConfigBoundControl._Ready(self)
    self.input.valueChanged:Connect(Callable.new(self, "_OnValueChanged"))
end

return ConfigSpinBoxC
