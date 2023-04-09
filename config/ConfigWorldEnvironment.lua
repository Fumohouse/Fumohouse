local ConfigManagerM = require("ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

local ConfigDirectionalLight3DImpl = {}
local ConfigWorldEnvironment = gdclass(nil, WorldEnvironment)
    :RegisterImpl(ConfigDirectionalLight3DImpl)

export type ConfigWorldEnvironment = WorldEnvironment & typeof(ConfigDirectionalLight3DImpl)

function ConfigDirectionalLight3DImpl.applySsr(self: ConfigWorldEnvironment)
    assert(self.environment)
    local ssrOption = ConfigManager.SSROptions[ConfigManager:Get("graphics/ssr") :: number + 1]
    self.environment.ssrEnabled = ssrOption.enabled
    self.environment.ssrMaxSteps = ssrOption.steps
end

function ConfigDirectionalLight3DImpl.applySsao(self: ConfigWorldEnvironment)
    assert(self.environment)
    local ssaoOption = ConfigManager.SSAOOptions[ConfigManager:Get("graphics/ssao") :: number + 1]
    self.environment.ssaoEnabled = ssaoOption.enabled
end

function ConfigDirectionalLight3DImpl.applySsil(self: ConfigWorldEnvironment)
    assert(self.environment)
    local ssilOption = ConfigManager.SSILOptions[ConfigManager:Get("graphics/ssil") :: number + 1]
    self.environment.ssilEnabled = ssilOption.enabled
end

function ConfigDirectionalLight3DImpl.applySdfgi(self: ConfigWorldEnvironment)
    assert(self.environment)
    local sdfgiOption = ConfigManager.SDFGIOptions[ConfigManager:Get("graphics/sdfgi") :: number + 1]
    self.environment.sdfgiEnabled = sdfgiOption.enabled
end

function ConfigDirectionalLight3DImpl.applyGlow(self: ConfigWorldEnvironment)
    assert(self.environment)
    local glowOption = ConfigManager.GlowOptions[ConfigManager:Get("graphics/glow") :: number + 1]
    self.environment.glowEnabled = glowOption.enabled
end

function ConfigDirectionalLight3DImpl.applyVolumetricFog(self: ConfigWorldEnvironment)
    assert(self.environment)
    local fogOption = ConfigManager.VolumetricFogOptions[ConfigManager:Get("graphics/volumetricFog") :: number + 1]
    self.environment.volumetricFogEnabled = fogOption.enabled
end

function ConfigDirectionalLight3DImpl.applyBrightness(self: ConfigWorldEnvironment)
    assert(self.environment)
    self.environment.adjustmentBrightness = ConfigManager:Get("graphics/brightness") :: number
end

function ConfigDirectionalLight3DImpl.applyContrast(self: ConfigWorldEnvironment)
    assert(self.environment)
    self.environment.adjustmentContrast = ConfigManager:Get("graphics/contrast") :: number
end

function ConfigDirectionalLight3DImpl.applySaturation(self: ConfigWorldEnvironment)
    assert(self.environment)
    self.environment.adjustmentSaturation = ConfigManager:Get("graphics/saturation") :: number
end

function ConfigDirectionalLight3DImpl._OnConfigValueChanged(self: ConfigWorldEnvironment, key: string)
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

ConfigWorldEnvironment:RegisterMethodAST("_OnConfigValueChanged")

function ConfigDirectionalLight3DImpl._Ready(self: ConfigWorldEnvironment)
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

ConfigWorldEnvironment:RegisterMethod("_Ready")

return ConfigWorldEnvironment