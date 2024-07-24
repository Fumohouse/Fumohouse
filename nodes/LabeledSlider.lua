--- @class
--- @extends Control
local LabeledSlider = {}
local LabeledSliderC = gdclass(LabeledSlider)

export type LabeledSlider = Control & typeof(LabeledSlider) & {
    --- @property
    --- @default "%.1f"
    formatString: string,

    label: Label,
}

--- @registerMethod
function LabeledSlider._OnValueChanged(self: LabeledSlider, value: number)
    self.label.text = string.format(self.formatString, value)
end

--- @registerMethod
function LabeledSlider._Ready(self: LabeledSlider)
    local slider = self:GetNode("HSlider") :: HSlider
    self.label = self:GetNode("Label") :: Label

    slider.valueChanged:Connect(Callable.new(self, "_OnValueChanged"))
    self:_OnValueChanged(slider.value)
end

return LabeledSliderC
