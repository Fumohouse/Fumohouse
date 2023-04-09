local LabeledSliderImpl = {}
local LabeledSlider = gdclass(nil, Control)
    :RegisterImpl(LabeledSliderImpl)

export type LabeledSlider = Control & typeof(LabeledSliderImpl) & {
    formatString: string,

    label: Label,
}

LabeledSlider:RegisterProperty("formatString", Enum.VariantType.STRING)
    :Default("%.1f")

function LabeledSliderImpl._OnValueChanged(self: LabeledSlider, value: number)
    self.label.text = string.format(self.formatString, value)
end

LabeledSlider:RegisterMethodAST("_OnValueChanged")

function LabeledSliderImpl._Ready(self: LabeledSlider)
    local slider = self:GetNode("HSlider") :: HSlider
    self.label = self:GetNode("Label") :: Label

    slider.valueChanged:Connect(Callable.new(self, "_OnValueChanged"))
    self:_OnValueChanged(slider.value)
end

LabeledSlider:RegisterMethod("_Ready")

return LabeledSlider
