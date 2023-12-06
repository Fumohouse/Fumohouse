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
    input: Control,
    --- @property
    revertButton: Button,

    --- @property
    key: string,

    --- @property
    features: PackedStringArray,

    updatingConfig: boolean,
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

function ConfigBoundControl._ApproxEqual(self: ConfigBoundControl, a: any, b: any)
    if a == b then
        return true
    end

    if type(a) == "number" and type(b) == "number" then
        return math.abs(a - b) < 1e-4
    end

    return false
end

function ConfigBoundControl.updateFromConfig(self: ConfigBoundControl)
    local value = ConfigManager:Get(self.key)

    if self.revertButton then
        self.revertButton.visible = not self:_ApproxEqual(value, ConfigManager:GetDefault(self.key))
    end

    if not self.updatingConfig then
        self:_SetValue(value)
    end
end

--- @registerMethod
function ConfigBoundControl._OnConfigValueChanged(self: ConfigBoundControl, key: string)
    if key ~= self.key then
        return
    end

    self:updateFromConfig()
end

--- @registerMethod
function ConfigBoundControl._OnRevertButtonPressed(self: ConfigBoundControl)
    ConfigManager:Set(self.key, ConfigManager:GetDefault(self.key))
end

function ConfigBoundControl._Init(self: ConfigBoundControl)
    self.updatingConfig = false
end

--- @registerMethod
function ConfigBoundControl._Ready(self: ConfigBoundControl)
    for _, platform: string in self.features do
        if not OS.singleton:HasFeature(platform) then
            self.visible = false
            break
        end
    end

    self:updateFromConfig()

    if self.revertButton then
        self.revertButton.pressed:Connect(Callable.new(self, "_OnRevertButtonPressed"))
    end

    ConfigManager.valueChanged:Connect(Callable.new(self, "_OnConfigValueChanged"))
end

return ConfigBoundControlC
