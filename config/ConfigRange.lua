local ConfigBoundControl = require("ConfigBoundControl")

local ConfigRangeImpl = {}
local ConfigRange = gdclass(nil, ConfigBoundControl)
    :RegisterImpl(ConfigRangeImpl)

export type ConfigRange = ConfigBoundControl.ConfigBoundControl & typeof(ConfigRangeImpl) & {
    input: Range,
    onRelease: boolean,

    isDragging: boolean,
}

ConfigRange:RegisterProperty("onRelease", Enum.VariantType.BOOL)

function ConfigRangeImpl._SetValue(self: ConfigRange, value: number)
    self.input.value = value
end

function ConfigRangeImpl._GetValue(self: ConfigRange): Variant
    return self.input.value
end

function ConfigRangeImpl._OnRangeValueChanged(self: ConfigRange, value: number)
    if self.onRelease and self.isDragging then
        return
    end

    self:UpdateConfigValue()
end

ConfigRange:RegisterMethodAST("_OnRangeValueChanged")

function ConfigRangeImpl._OnDragStarted(self: ConfigRange)
    self.isDragging = true
end

ConfigRange:RegisterMethodAST("_OnDragStarted")

function ConfigRangeImpl._OnDragEnded(self: ConfigRange, valueChanged: boolean)
    self.isDragging = false

    if valueChanged then
        self:UpdateConfigValue()
    end
end

ConfigRange:RegisterMethodAST("_OnDragEnded")

function ConfigRangeImpl._Init(self: ConfigRange)
    self.isDragging = false
end

function ConfigRangeImpl._Ready(self: ConfigRange)
    ConfigBoundControl._Ready(self)

    self.input.valueChanged:Connect(Callable.new(self, "_OnRangeValueChanged"))

    if self.onRelease then
        local slider = self.input :: Slider
        slider.dragStarted:Connect(Callable.new(self, "_OnDragStarted"))
        slider.dragEnded:Connect(Callable.new(self, "_OnDragEnded"))
    end
end

return ConfigRange
