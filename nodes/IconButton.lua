local IconButtonImpl = {}
local IconButton = gdclass(nil, TextureButton)
    :RegisterImpl(IconButtonImpl)

type IconButtonT = {
    transitionDuration: number,
    hoverColor: Color,
    pressColor: Color,

    baseColor: Color,
}

export type IconButton = TextureButton & IconButtonT & typeof(IconButtonImpl)

IconButton:RegisterProperty("transitionDuration", Enum.VariantType.FLOAT)
    :Default(0.15)

IconButton:RegisterProperty("hoverColor", Enum.VariantType.COLOR)
    :Default(Color.new(0.8, 0.8, 0.8))

IconButton:RegisterProperty("pressColor", Enum.VariantType.COLOR)
    :Default(Color.new(0.6, 0.6, 0.6))

function IconButtonImpl._Ready(self: IconButton)
    self.baseColor = self.modulate

    self.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    self.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
    self.buttonDown:Connect(Callable.new(self, "_OnButtonDown"))
    self.buttonUp:Connect(Callable.new(self, "_OnButtonUp"))
end

IconButton:RegisterMethod("_Ready")

function IconButtonImpl.beginTween(self: IconButton)
    return self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
end

function IconButtonImpl._OnMouseEntered(self: IconButton)
    if self:IsPressed() then
        return
    end

    self:beginTween():TweenProperty(self, "modulate", self.hoverColor, self.transitionDuration)
end

IconButton:RegisterMethod("_OnMouseEntered")

function IconButtonImpl._OnMouseExited(self: IconButton)
    if self:IsPressed() then
        return
    end

    self:beginTween():TweenProperty(self, "modulate", self.baseColor, self.transitionDuration)
end

IconButton:RegisterMethod("_OnMouseExited")

function IconButtonImpl._OnButtonDown(self: IconButton)
    self:beginTween():TweenProperty(self, "modulate", self.pressColor, self.transitionDuration)
end

IconButton:RegisterMethod("_OnButtonDown")

function IconButtonImpl._OnButtonUp(self: IconButton)
    local target = if self:IsHovered() then self.hoverColor else self.baseColor
    self:beginTween():TweenProperty(self, "modulate", target, self.transitionDuration)
end

IconButton:RegisterMethod("_OnButtonUp")

return IconButton
