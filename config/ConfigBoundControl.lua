local ConfigManagerM = require("ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class
--- @extends Control
--- @permissions INTERNAL OS
local ConfigBoundControl = {}
local ConfigBoundControlC = gdclass(ConfigBoundControl)

--- @classType ConfigBoundControl
export type ConfigBoundControl = Control & typeof(ConfigBoundControl) & {
    --- @property
    inputPath: NodePathConstrained<Control>,

    --- @property
    key: string,

    --- @property
    features: PackedStringArray,

    updatingConfig: boolean,
    input: Control,
}

function ConfigBoundControl._SetValue(self: ConfigBoundControl, value: Variant)
end

function ConfigBoundControl._GetValue(self: ConfigBoundControl): Variant
    return nil
end

function ConfigBoundControl.UpdateConfigValue(self: ConfigBoundControl)
    self.updatingConfig = true
    ConfigManager:Set(self.key, self:_GetValue())
    self.updatingConfig = false
end

--- @registerMethod
function ConfigBoundControl._OnConfigValueChanged(self: ConfigBoundControl, key: string)
    if self.updatingConfig or key ~= self.key then
        return
    end

    self:_SetValue(ConfigManager:Get(key))
end

function ConfigBoundControl._Init(self: ConfigBoundControl)
    self.updatingConfig = false
end

--- @registerMethod
function ConfigBoundControl._Ready(self: ConfigBoundControl)
    assert(self.inputPath ~= "")
    self.input = self:GetNode(self.inputPath) :: Control

    for _, platform: string in self.features do
        if not OS.singleton:HasFeature(platform) then
            self.visible = false
            break
        end
    end

    self:_SetValue(ConfigManager:Get(self.key))
    ConfigManager.valueChanged:Connect(Callable.new(self, "_OnConfigValueChanged"))
end

return ConfigBoundControlC
