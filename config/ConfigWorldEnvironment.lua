local ConfigManagerM = require("ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class
--- @extends WorldEnvironment
local ConfigWorldEnvironment = {}
local ConfigWorldEnvironmentC = gdclass(ConfigWorldEnvironment)

--- @classType ConfigWorldEnvironment
export type ConfigWorldEnvironment = WorldEnvironment & typeof(ConfigWorldEnvironment)

function ConfigWorldEnvironment.applySsr(self: ConfigWorldEnvironment)
    assert(self.environment)
    local ssrOption = ConfigManager.SSROptions[ConfigManager:Get("graphics/ssr") :: number + 1]
    self.environment.ssrEnabled = ssrOption.enabled
    self.environment.ssrMaxSteps = ssrOption.steps
end

function ConfigWorldEnvironment.applySsao(self: ConfigWorldEnvironment)
    assert(self.environment)
    local ssaoOption = ConfigManager.SSAOOptions[ConfigManager:Get("graphics/ssao") :: number + 1]
    self.environment.ssaoEnabled = ssaoOption.enabled
end

function ConfigWorldEnvironment.applySsil(self: ConfigWorldEnvironment)
    assert(self.environment)
    local ssilOption = ConfigManager.SSILOptions[ConfigManager:Get("graphics/ssil") :: number + 1]
    self.environment.ssilEnabled = ssilOption.enabled
end

function ConfigWorldEnvironment.applySdfgi(self: ConfigWorldEnvironment)
    assert(self.environment)
    local sdfgiOption = ConfigManager.SDFGIOptions[ConfigManager:Get("graphics/sdfgi") :: number + 1]
    self.environment.sdfgiEnabled = sdfgiOption.enabled
end

function ConfigWorldEnvironment.applyGlow(self: ConfigWorldEnvironment)
    assert(self.environment)
    local glowOption = ConfigManager.GlowOptions[ConfigManager:Get("graphics/glow") :: number + 1]
    self.environment.glowEnabled = glowOption.enabled
end

function ConfigWorldEnvironment.applyVolumetricFog(self: ConfigWorldEnvironment)
    assert(self.environment)
    local fogOption = ConfigManager.VolumetricFogOptions[ConfigManager:Get("graphics/volumetricFog") :: number + 1]
    self.environment.volumetricFogEnabled = fogOption.enabled
end

function ConfigWorldEnvironment.applyBrightness(self: ConfigWorldEnvironment)
    assert(self.environment)
    self.environment.adjustmentBrightness = ConfigManager:Get("graphics/brightness") :: number
end

function ConfigWorldEnvironment.applyContrast(self: ConfigWorldEnvironment)
    assert(self.environment)
    self.environment.adjustmentContrast = ConfigManager:Get("graphics/contrast") :: number
end

function ConfigWorldEnvironment.applySaturation(self: ConfigWorldEnvironment)
    assert(self.environment)
    self.environment.adjustmentSaturation = ConfigManager:Get("graphics/saturation") :: number
end

--- @registerMethod
function ConfigWorldEnvironment._OnConfigValueChanged(self: ConfigWorldEnvironment, key: string)
    if key == "graphics/ssr" then
        self:applySsr()
    elseif key == "graphics/ssao" then
        self:applySsao()
    elseif key == "graphics/ssil" then
        self:applySsil()
    elseif key == "graphics/sdfgi" then
        self:applySdfgi()
    elseif key == "graphics/glow" then
        self:applyGlow()
    elseif key == "graphics/volumetricFog" then
        self:applyVolumetricFog()
    elseif key == "graphics/brightness" then
        self:applyBrightness()
    elseif key == "graphics/contrast" then
        self:applyContrast()
    elseif key == "graphics/saturation" then
        self:applySaturation()
    end
end

--- @registerMethod
function ConfigWorldEnvironment._Ready(self: ConfigWorldEnvironment)
    self:applySsr()
    self:applySsao()
    self:applySsil()
    self:applySdfgi()
    self:applyGlow()
    self:applyVolumetricFog()
    self:applyBrightness()
    self:applyContrast()
    self:applySaturation()
    ConfigManager.valueChanged:Connect(Callable.new(self, "_OnConfigValueChanged"))
end

return ConfigWorldEnvironmentC
