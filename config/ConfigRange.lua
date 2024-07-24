local ConfigBoundControl = require("ConfigBoundControl")

--- @class
--- @extends ConfigBoundControl
local ConfigRange = {}
local ConfigRangeC = gdclass(ConfigRange)

export type ConfigRange = ConfigBoundControl.ConfigBoundControl & typeof(ConfigRange) & {
    input: Range,

    --- @property
    onRelease: boolean,

    isDragging: boolean,
}

function ConfigRange._SetValue(self: ConfigRange, value: number)
    self.input.value = value
end

function ConfigRange._GetValue(self: ConfigRange): Variant
    return self.input.value
end

--- @registerMethod
function ConfigRange._OnRangeValueChanged(self: ConfigRange, value: number)
    if self.onRelease and self.isDragging then
        return
    end

    self:UpdateConfigValue()
end

--- @registerMethod
function ConfigRange._OnDragStarted(self: ConfigRange)
    self.isDragging = true
end

--- @registerMethod
function ConfigRange._OnDragEnded(self: ConfigRange, valueChanged: boolean)
    self.isDragging = false

    if valueChanged then
        self:UpdateConfigValue()
    end
end

function ConfigRange._Init(self: ConfigRange)
    self.isDragging = false
end

function ConfigRange._Ready(self: ConfigRange)
    ConfigBoundControl._Ready(self)

    self.input.valueChanged:Connect(Callable.new(self, "_OnRangeValueChanged"))

    if self.onRelease then
        local slider = self.input :: Slider
        slider.dragStarted:Connect(Callable.new(self, "_OnDragStarted"))
        slider.dragEnded:Connect(Callable.new(self, "_OnDragEnded"))
    end
end

return ConfigRangeC
