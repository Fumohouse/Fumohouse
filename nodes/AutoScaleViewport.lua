--- @class AutoScalingViewport
--- @extends SubViewport
local AutoScaleViewport = {}
local AutoScaleViewportC = gdclass(AutoScaleViewport)

export type AutoScaleViewport = SubViewport & typeof(AutoScaleViewport) & {
    baseSize: Vector2i,
    viewport: Window,
}

--- @registerMethod
function AutoScaleViewport._Ready(self: AutoScaleViewport)
    self.baseSize = self.size
    self.viewport = self:GetWindow()

    self:_OnViewportSizeChanged()
    self.viewport.sizeChanged:Connect(Callable.new(self, "_OnViewportSizeChanged"))
end

--- @registerMethod
function AutoScaleViewport._OnViewportSizeChanged(self: AutoScaleViewport)
    local scale = Vector2.new(self.viewport.size) / Vector2.new(self.viewport.contentScaleSize)
    self.size = Vector2i.new(self.baseSize * math.max(scale.x, scale.y))
end

return AutoScaleViewportC
