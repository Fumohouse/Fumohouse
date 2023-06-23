local ConfigManagerM = require("ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class
--- @extends DirectionalLight3D
local ConfigDirectionalLight3D = {}
local ConfigDirectionalLight3DC = gdclass(ConfigDirectionalLight3D)

--- @classType ConfigDirectionalLight3D
export type ConfigDirectionalLight3D = DirectionalLight3D & typeof(ConfigDirectionalLight3D)

function ConfigDirectionalLight3D.applyBias(self: ConfigDirectionalLight3D)
    self.shadowBias = ConfigManager.ShadowQualityOptions[ConfigManager:Get("graphics/shadows/quality") :: number + 1].directionalBias
end

--- @registerMethod
function ConfigDirectionalLight3D._OnConfigValueChanged(self: ConfigDirectionalLight3D, key: string)
    if key == "graphics/shadows/quality" then
        self:applyBias()
    end
end

--- @registerMethod
function ConfigDirectionalLight3D._Ready(self: ConfigDirectionalLight3D)
    self:applyBias()
    ConfigManager.valueChanged:Connect(Callable.new(self, "_OnConfigValueChanged"))
end

return ConfigDirectionalLight3DC
