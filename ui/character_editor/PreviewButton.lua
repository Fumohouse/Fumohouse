--- @class
--- @extends Button
local PreviewButton = {}
local PreviewButtonC = gdclass(PreviewButton)

--- @classType PreviewButton
export type PreviewButton = Button & typeof(PreviewButton) & {
    --- @property
    indicator: Control,
}

--- @registerMethod
function PreviewButton._Ready(self: PreviewButton)
    self:_OnToggled(self.buttonPressed)
    self.toggled:Connect(Callable.new(self, "_OnToggled"))
end

--- @registerMethod
function PreviewButton._OnToggled(self: PreviewButton, on: boolean)
    self.indicator.visible = on
end

return PreviewButtonC
