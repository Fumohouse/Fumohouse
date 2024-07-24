--- @class
--- @extends TextureButton
local IconButton = {}
local IconButtonC = gdclass(IconButton)

export type IconButton = TextureButton & typeof(IconButton) & {
    --- @property
    --- @default 0.15
    transitionDuration: number,

    --- @property
    --- @default Color(0.8, 0.8, 0.8, 1.0)
    hoverColor: Color,

    --- @property
    --- @default Color(0.6, 0.6, 0.6, 1.0)
    pressColor: Color,

    baseColor: Color,
}

--- @registerMethod
function IconButton._Ready(self: IconButton)
    self.baseColor = self.modulate

    self.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    self.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
    self.buttonDown:Connect(Callable.new(self, "_OnButtonDown"))
    self.buttonUp:Connect(Callable.new(self, "_OnButtonUp"))
end

function IconButton.beginTween(self: IconButton)
    return self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
end

--- @registerMethod
function IconButton._OnMouseEntered(self: IconButton)
    if self:IsPressed() then
        return
    end

    self:beginTween():TweenProperty(self, "modulate", self.hoverColor, self.transitionDuration)
end

--- @registerMethod
function IconButton._OnMouseExited(self: IconButton)
    if self:IsPressed() then
        return
    end

    self:beginTween():TweenProperty(self, "modulate", self.baseColor, self.transitionDuration)
end

--- @registerMethod
function IconButton._OnButtonDown(self: IconButton)
    self:beginTween():TweenProperty(self, "modulate", self.pressColor, self.transitionDuration)
end

--- @registerMethod
function IconButton._OnButtonUp(self: IconButton)
    local target = if self:IsHovered() then self.hoverColor else self.baseColor
    self:beginTween():TweenProperty(self, "modulate", target, self.transitionDuration)
end

return IconButtonC
