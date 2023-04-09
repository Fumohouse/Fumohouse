local ConfigManagerM = require("ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

local ConfigBoundControlImpl = {}
local ConfigBoundControl = gdclass(nil, Control)
    :Permissions(bit32.bor(Enum.Permissions.INTERNAL, Enum.Permissions.OS))
    :RegisterImpl(ConfigBoundControlImpl)

export type ConfigBoundControl = Control & typeof(ConfigBoundControlImpl) & {
    inputPath: string,
    key: string,
    features: PackedStringArray,

    updatingConfig: boolean,
    input: Control,
}

ConfigBoundControl:RegisterProperty("inputPath", Enum.VariantType.NODE_PATH)
    :NodePath(Control)

ConfigBoundControl:RegisterProperty("key", Enum.VariantType.STRING)
ConfigBoundControl:RegisterProperty("features", Enum.VariantType.PACKED_STRING_ARRAY)

function ConfigBoundControlImpl._SetValue(self: ConfigBoundControl, value: Variant)
end

function ConfigBoundControlImpl._GetValue(self: ConfigBoundControl): Variant
    return nil
end

function ConfigBoundControlImpl.UpdateConfigValue(self: ConfigBoundControl)
    self.updatingConfig = true
    ConfigManager:Set(self.key, self:_GetValue())
    self.updatingConfig = false
end

function ConfigBoundControlImpl._OnConfigValueChanged(self: ConfigBoundControl, key: string)
    if self.updatingConfig or key ~= self.key then
        return
    end

    self:_SetValue(ConfigManager:Get(key))
end

ConfigBoundControl:RegisterMethodAST("_OnConfigValueChanged")

function ConfigBoundControlImpl._Init(self: ConfigBoundControl)
    self.updatingConfig = false
end

function ConfigBoundControlImpl._Ready(self: ConfigBoundControl)
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

ConfigBoundControl:RegisterMethod("_Ready")

return ConfigBoundControl
