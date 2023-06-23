--- @class OptionButtonTransparent
--- @extends OptionButton
local OptionButtonTransparent = {}
local OptionButtonTransparentC = gdclass(OptionButtonTransparent)

--- @classType OptionButtonTransparent
export type OptionButtonTransparent = OptionButton & typeof(OptionButtonTransparent) & {
    --- @property
    --- @default 4
    menuSpacing: integer,
}

--- @registerMethod
function OptionButtonTransparent._OnPressed(self: OptionButtonTransparent)
    self:GetPopup().position += Vector2i.new(0, self.menuSpacing)
end

--- @registerMethod
function OptionButtonTransparent._Ready(self: OptionButtonTransparent)
    -- Otherwise, popup will have filled in corners when there is a corner radius
    self:GetPopup().transparentBg = true
    self.pressed:Connect(Callable.new(self, "_OnPressed"))
end

return OptionButtonTransparentC
