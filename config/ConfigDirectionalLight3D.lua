local ConfigManagerM = require("ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

local ConfigDirectionalLight3DImpl = {}
local ConfigDirectionalLight3D = gdclass(nil, DirectionalLight3D)
    :RegisterImpl(ConfigDirectionalLight3DImpl)

export type ConfigDirectionalLight3D = DirectionalLight3D & typeof(ConfigDirectionalLight3DImpl)

function ConfigDirectionalLight3DImpl.applyBias(self: ConfigDirectionalLight3D)
    self.shadowBias = ConfigManager.ShadowQualityOptions[ConfigManager:Get("graphics/shadows/quality") :: number + 1].directionalBias
end

function ConfigDirectionalLight3DImpl._OnConfigValueChanged(self: ConfigDirectionalLight3D, key: string)
    if key == "graphics/shadows/quality" then
        self:applyBias()
    end
end

ConfigDirectionalLight3D:RegisterMethodAST("_OnConfigValueChanged")

function ConfigDirectionalLight3DImpl._Ready(self: ConfigDirectionalLight3D)
    self:applyBias()
    ConfigManager.valueChanged:Connect(Callable.new(self, "_OnConfigValueChanged"))
end

ConfigDirectionalLight3D:RegisterMethod("_Ready")

return ConfigDirectionalLight3D