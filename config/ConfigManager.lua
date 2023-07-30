--- @class
--- @extends Node
--- @permissions INTERNAL
local ConfigManager = {}
local ConfigManagerC = gdclass(ConfigManager)

type ConfigSetHandler = (value: any) -> ()

type ConfigKey = {
    type: string,
    isObject: boolean,
    default: Variant,
    handler: ConfigSetHandler?,
    restartRequired: boolean,
}

--- @classType ConfigManager
export type ConfigManager = Node & typeof(ConfigManager) & {
    --- @signal
    valueChanged: SignalWithArgs<(key: string) -> ()>,

    --- @signal
    restartRequired: Signal,

    config: ConfigFile,
    projectSettingsModified: boolean,
    autosaveTimeout: number,
    options: {[string]: ConfigKey},
}

local CONFIG_LOCATION = "user://config.ini"
local AUTOSAVE_TIMEOUT = 30

local viewportStartSize = Vector2i.new(
    ProjectSettings.singleton:Get("display/window/size/viewport_width") :: number,
    ProjectSettings.singleton:Get("display/window/size/viewport_height") :: number
)

-- I/O --

local function splitKey(key: string)
    local idx = assert(string.find(key, "/", nil, true))
    return string.sub(key, 1, idx - 1), string.sub(key, idx + 1)
end

function ConfigManager.Has(self: ConfigManager, key: string)
    return self.config:HasSectionKey(splitKey(key))
end

function ConfigManager.Get(self: ConfigManager, key: string)
    return self.config:GetValue(splitKey(key))
end

function ConfigManager.Set(self: ConfigManager, key: string, value: Variant, isInit: boolean?)
    if self:Has(key) and self:Get(key) == value then
        return
    end

    local keyInfo = assert(self.options[key])

    local typeValid: boolean

    if keyInfo.isObject then
        local success, result = pcall(function() return (value :: Object):IsA(keyInfo.type) end)
        typeValid = success and result
    else
        typeValid = typeof(value) == keyInfo.type
    end

    assert(typeValid, `Config value {key} is the wrong type (got {typeof(value)}, expected {keyInfo.type})`)

    local fileSection, fileKey = splitKey(key)
    self.config:SetValue(fileSection, fileKey, value)

    if keyInfo.handler then
        keyInfo.handler(value)
    end

    if not isInit and keyInfo.restartRequired then
        self.restartRequired:Emit()
    end

    self.valueChanged:Emit(key)

    self.autosaveTimeout = AUTOSAVE_TIMEOUT
end

function ConfigManager.Load(self: ConfigManager)
    local err = self.config:Load(CONFIG_LOCATION)

    if err ~= Enum.Error.OK and err ~= Enum.Error.ERR_FILE_NOT_FOUND then
        push_warning(`Failed to load config file at {CONFIG_LOCATION} (error {err}).`)
    end

    -- Initialize values
    for key, keyInfo in self.options do
        if self:Has(key) then
            local val = self:Get(key)

            if typeof(val) == keyInfo.type then
                if keyInfo.handler then
                    keyInfo.handler(val)
                end

                continue
            end
        end

        -- Fall back to default value if current one is missing or invalid.
        -- This will also call the handler automatically.
        self:Set(key, keyInfo.default, true)
    end
end

function ConfigManager.Save(self: ConfigManager)
    local err = self.config:Save(CONFIG_LOCATION)

    if err == Enum.Error.OK then
        self.autosaveTimeout = 0
    else
        error(`Failed to save config file to {CONFIG_LOCATION} (error {err}).`)
    end

    if self.projectSettingsModified then
        local overrideLocation = ProjectSettings.singleton:Get("application/config/project_settings_override") :: string
        err = ProjectSettings.singleton:SaveCustom(overrideLocation)
        if err == Enum.Error.OK then
            self.projectSettingsModified = false
        else
            error(`Failed to save project settings override file to {overrideLocation} (error {err}).`)
        end
    end
end

-- Autosave --

--- @registerMethod
function ConfigManager._Process(self: ConfigManager, delta: number)
    if self.autosaveTimeout > 0 then
        self.autosaveTimeout = math.max(0, self.autosaveTimeout - delta)

        if self.autosaveTimeout == 0 then
            self:Save()
        end
    end
end

--- @registerMethod
function ConfigManager._ExitTree(self: ConfigManager)
    if self.autosaveTimeout > 0 then
        self:Save()
    end
end

-- Options --

-- Graphics options and settings from https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd
ConfigManager.ShadowQualityOptions = {
    {
        directionalSize = 512,
        directionalBias = 0.06,
        positionalSize = 0
    },
    {
        directionalSize = 1024,
        directionalBias = 0.04,
        positionalSize = 1024
    },
    {
        directionalSize = 2048,
        directionalBias = 0.03,
        positionalSize = 2048
    },
    {
        directionalSize = 4096,
        directionalBias = 0.02,
        positionalSize = 4096
    },
    {
        directionalSize = 8192,
        directionalBias = 0.01,
        positionalSize = 8192
    },
    {
        directionalSize = 16384,
        directionalBias = 0.005,
        positionalSize = 16384
    }
}

ConfigManager.SSROptions = {
    {enabled = false, steps = 0},
    {enabled = true, steps = 8},
    {enabled = true, steps = 32},
    {enabled = true, steps = 56},
}

ConfigManager.SSAOOptions = {
    {
        enabled = false,
        quality = -1,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSAOQuality.VERY_LOW,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSAOQuality.VERY_LOW,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSAOQuality.MEDIUM,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSAOQuality.HIGH,
    },
}

ConfigManager.SSILOptions = {
    {
        enabled = false,
        quality = -1
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSILQuality.VERY_LOW,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSILQuality.LOW,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSILQuality.MEDIUM,
    },
    {
        enabled = true,
        quality = RenderingServer.EnvironmentSSILQuality.HIGH,
    },
}

ConfigManager.SDFGIOptions = {
    {
        enabled = false,
        halfRes = false,
    },
    {
        enabled = true,
        halfRes = true,
    },
    {
        enabled = true,
        halfRes = false,
    },
}

ConfigManager.GlowOptions = {
    {
        enabled = false,
        upscale = false,
    },
    {
        enabled = true,
        upscale = false,
    },
    {
        enabled = true,
        upscale = true,
    },
}

ConfigManager.VolumetricFogOptions = {
    {
        enabled = false,
        filter = false,
    },
    {
        enabled = true,
        filter = false,
    },
    {
        enabled = true,
        filter = true,
    },
}

function ConfigManager.addOption(self: ConfigManager, key: string, defaultValue: Variant, handler: ConfigSetHandler?, restartRequired: boolean?, typeOverride: string?, isObject: boolean?)
    assert(not self.options[key])

    self.options[key] = {
        type = typeOverride or typeof(defaultValue),
        isObject = isObject == true,
        default = defaultValue,
        handler = handler,
        restartRequired = restartRequired == true,
    }
end

function ConfigManager.addAudioBus(self: ConfigManager, bus: string)
    local idx = AudioServer.singleton:GetBusIndex(bus)
    assert(idx >= 0)

    self:addOption(`audio/bus/{bus}/volume`, 80, function(value: number)
        AudioServer.singleton:SetBusVolumeDb(idx, linear_to_db(value / 100))
    end)
end

local function evtMod(ev: InputEventWithModifiers, ctrlPressed: boolean?, shiftPressed: boolean?, altPressed: boolean?, metaPressed: boolean?)
    ev.ctrlPressed = ctrlPressed == true
    ev.shiftPressed = shiftPressed == true
    ev.altPressed = altPressed == true
    ev.metaPressed = metaPressed == true
    return ev
end

local function keyEvent(key: EnumKey)
    local ev = InputEventKey.new()
    ev.physicalKeycode = key
    return ev
end

local function mbEvent(button: EnumMouseButton)
    local ev = InputEventMouseButton.new()
    ev.buttonIndex = button
    return ev
end

function ConfigManager.addAction(self: ConfigManager, action: string, default: InputEvent)
    InputMap.singleton:AddAction(action)

    self:addOption(`input/action/{action}/bind`, default, function(value: InputEvent)
        InputMap.singleton:ActionEraseEvents(action)
        InputMap.singleton:ActionAddEvent(action, value)
    end, false, "InputEvent", true)
end

function ConfigManager.initOptions(self: ConfigManager)
    -- Graphics
    self:addOption("graphics/renderingMethod", 0, function(value: number)
        local values = {"forward_plus", "mobile", "gl_compatibility"}
        -- This option isn't supported on mobile and web
        ProjectSettings.singleton:Set("rendering/renderer/rendering_method", values[value + 1])
        self.projectSettingsModified = true
    end, true)

    local windowModes = {Window.Mode.WINDOWED, Window.Mode.MAXIMIZED, Window.Mode.FULLSCREEN, Window.Mode.EXCLUSIVE_FULLSCREEN}
    self:addOption("graphics/windowMode", Window.Mode.WINDOWED, function(value: number)
        self:GetTree().root:SetMode(windowModes[value + 1])
    end)

    self:addOption("graphics/vsyncMode", DisplayServer.VSyncMode.ENABLED, function(value: number)
        DisplayServer.singleton:WindowSetVsyncMode(value)
    end)

    self:addOption("graphics/uiScale", 1, function(value: number)
        self:GetTree().root:SetContentScaleSize(Vector2i.new(viewportStartSize * value))
    end)

    self:addOption("graphics/fov", 75)

    self:addOption("graphics/scaling3d/mode", Viewport.Scaling3DMode.BILINEAR, function(value: number)
        if value == Viewport.Scaling3DMode.FSR then
            self:Set("graphics/scaling3d/scale", math.min(1, self:Get("graphics/scaling3d/scale") :: number))
        end

        self:GetViewport().scaling3DMode = value
    end)

    self:addOption("graphics/scaling3d/fsrSharpness", 0.2, function(value: number)
        self:GetViewport().fsrSharpness = value
    end)

    self:addOption("graphics/scaling3d/scale", 1, function(value: number)
        if value > 1 then
            self:Set("graphics/scaling3d/mode", Viewport.Scaling3DMode.BILINEAR)
        end

        self:GetViewport().scaling3DScale = value
    end)

    self:addOption("graphics/msaa3d", Viewport.MSAA.DISABLED, function(value: number)
        self:GetViewport().msaa3D = value
    end)

    self:addOption("graphics/taa", false, function(value: boolean)
        self:GetViewport().useTaa = value
    end)

    self:addOption("graphics/screenSpaceAa", Viewport.ScreenSpaceAA.DISABLED, function(value: number)
        self:GetViewport().screenSpaceAa = value
    end)

    self:addOption("graphics/shadows/quality", 3, function(value: number)
        local option = ConfigManager.ShadowQualityOptions[value + 1]
        RenderingServer.singleton:DirectionalShadowAtlasSetSize(option.directionalSize, true)
        self:GetViewport().positionalShadowAtlasSize = option.positionalSize
    end)

    local shadowFilterSettings = {
        RenderingServer.ShadowQuality.HARD,
        RenderingServer.ShadowQuality.SOFT_VERY_LOW,
        RenderingServer.ShadowQuality.SOFT_LOW,
        RenderingServer.ShadowQuality.SOFT_MEDIUM,
        RenderingServer.ShadowQuality.SOFT_HIGH,
        RenderingServer.ShadowQuality.SOFT_ULTRA
    }

    self:addOption("graphics/shadows/filter", 2, function(value: number)
        local quality = shadowFilterSettings[value + 1]
        RenderingServer.singleton:DirectionalSoftShadowFilterSetQuality(quality)
        RenderingServer.singleton:PositionalSoftShadowFilterSetQuality(quality)
    end)

    local lodThresholdSettings = {8, 4, 2, 1, 0}
    self:addOption("graphics/lodThreshold", 3, function(value: number)
        self:GetViewport().meshLodThreshold = lodThresholdSettings[value + 1]
    end)

    self:addOption("graphics/ssr", 0)

    self:addOption("graphics/ssao", 0, function(value: number)
        local ssaoOption = ConfigManager.SSAOOptions[value + 1]
        if ssaoOption.enabled then
            RenderingServer.singleton:EnvironmentSetSsaoQuality(ssaoOption.quality, true, 0.5, 2, 50, 300)
        end
    end)

    self:addOption("graphics/ssil", 0, function(value: number)
        local ssilOption = ConfigManager.SSILOptions[value + 1]
        if ssilOption.enabled then
            RenderingServer.singleton:EnvironmentSetSsilQuality(ssilOption.quality, true, 0.5, 4, 50, 300)
        end
    end)

    self:addOption("graphics/sdfgi", 0, function(value: number)
        local sdfgiOption = ConfigManager.SDFGIOptions[value + 1]
        if sdfgiOption.enabled then
            RenderingServer.singleton:GiSetUseHalfResolution(sdfgiOption.halfRes)
        end
    end)

    self:addOption("graphics/glow", 0, function(value: number)
        local glowOption = ConfigManager.GlowOptions[value + 1]
        if glowOption.enabled then
            RenderingServer.singleton:EnvironmentGlowSetUseBicubicUpscale(glowOption.upscale)
        end
    end)

    self:addOption("graphics/volumetricFog", 0, function(value: number)
        local fogOption = ConfigManager.VolumetricFogOptions[value + 1]
        if fogOption.enabled then
            RenderingServer.singleton:EnvironmentSetVolumetricFogFilterActive(fogOption.filter)
        end
    end)

    self:addOption("graphics/brightness", 1)
    self:addOption("graphics/contrast", 1)
    self:addOption("graphics/saturation", 1)

    -- Audio
    self:addOption("audio/outputDevice", "Default", function(value: string)
        local devices = AudioServer.singleton:GetOutputDeviceList()
        if devices:Has(value) then
            AudioServer.singleton.outputDevice = value
        else
            push_warning(`Requested audio output device {value} not found. Falling back to default.`)
            AudioServer.singleton.outputDevice = "Default"
        end
    end)

    self:addAudioBus("Master")
    self:addAudioBus("Music")

    -- Input
    self:addOption("input/sens/camera/firstPerson", 0.3)
    self:addOption("input/sens/camera/thirdPerson", 1)
    self:addOption("input/sens/cameraZoom", 1)

    self:addAction("move_forward", keyEvent(Enum.Key.W))
    self:addAction("move_backward", keyEvent(Enum.Key.S))
    self:addAction("move_left", keyEvent(Enum.Key.A))
    self:addAction("move_right", keyEvent(Enum.Key.D))
    self:addAction("move_jump", keyEvent(Enum.Key.SPACE))
    self:addAction("move_sit", keyEvent(Enum.Key.C))
    self:addAction("move_run", keyEvent(Enum.Key.SHIFT))

    self:addAction("camera_rotate", mbEvent(Enum.MouseButton.RIGHT))
    self:addAction("camera_zoom_in", mbEvent(Enum.MouseButton.WHEEL_UP))
    self:addAction("camera_zoom_out", mbEvent(Enum.MouseButton.WHEEL_DOWN))

    self:addAction("menu_back", keyEvent(Enum.Key.ESCAPE))

    self:addAction("debug_1", keyEvent(Enum.Key.F1))
    self:addAction("debug_2", keyEvent(Enum.Key.F2))
    self:addAction("debug_3", keyEvent(Enum.Key.F3))
end

-- Initialization --

function ConfigManager._Init(self: ConfigManager)
    self.config = ConfigFile.new()
    self.projectSettingsModified = false
    self.autosaveTimeout = 0
    self.options = {}

    self:initOptions()
end

--- @registerMethod
function ConfigManager._Ready(self: ConfigManager)
    self:Load()
end

return ConfigManagerC
