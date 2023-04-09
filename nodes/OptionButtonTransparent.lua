local OptionButtonTransparentImpl = {}
local OptionButtonTransparent = gdclass("OptionButtonTransparent", OptionButton)
    :RegisterImpl(OptionButtonTransparentImpl)

export type OptionButtonTransparent = OptionButton & typeof(OptionButtonTransparentImpl) & {
    menuSpacing: number,
}

OptionButtonTransparent:RegisterProperty("menuSpacing", Enum.VariantType.INT)
    :Default(4)

function OptionButtonTransparentImpl._OnPressed(self: OptionButtonTransparent)
    self:GetPopup().position += Vector2i.new(0, self.menuSpacing)
end

OptionButtonTransparent:RegisterMethod("_OnPressed")

function OptionButtonTransparentImpl._Ready(self: OptionButtonTransparent)
    -- Otherwise, popup will have filled in corners when there is a corner radius
    self:GetPopup().transparentBg = true
    self.pressed:Connect(Callable.new(self, "_OnPressed"))
end

OptionButtonTransparent:RegisterMethod("_Ready")

return OptionButtonTransparent
