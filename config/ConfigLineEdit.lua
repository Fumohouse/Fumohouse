local ConfigBoundControl = require("ConfigBoundControl")

--- @class
--- @extends ConfigBoundControl
local ConfigLineEdit = {}
local ConfigLineEditC = gdclass(ConfigLineEdit)

--- @classType ConfigLineEdit
export type ConfigLineEdit = ConfigBoundControl.ConfigBoundControl & typeof(ConfigLineEdit) & {
    input: LineEdit,
}

function ConfigLineEdit._SetValue(self: ConfigLineEdit, value: string)
    self.input.text = value
end

function ConfigLineEdit._GetValue(self: ConfigLineEdit): Variant
    return self.input.text
end

--- @registerMethod
function ConfigLineEdit._OnTextChanged(self: ConfigLineEdit, text: string)
    self:UpdateConfigValue()
end

function ConfigLineEdit._Ready(self: ConfigLineEdit)
    ConfigBoundControl._Ready(self)
    self.input.textChanged:Connect(Callable.new(self, "_OnTextChanged"))
end

return ConfigLineEditC
