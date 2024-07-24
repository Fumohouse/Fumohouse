--- @class
--- @extends Button
local NavButton = {}
local NavButtonC = gdclass(NavButton)

export type NavButton = Button & typeof(NavButton) & {
    origWidth: number,

    tween: Tween?,
}

local EXPAND = 20

function NavButton.TransitionArgs(self: NavButton)
    return {
        inArgs = {},
        outArgs = { self:GetIndex() }
    }
end

--- @registerMethod
function NavButton._Ready(self: NavButton)
    self.origWidth = self.size.x

    self.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    self.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
end

--- @registerMethod
function NavButton._OnMouseEntered(self: NavButton)
    if self.tween then
        self.tween:Kill()
    end

    self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.BACK)
        :TweenProperty(self, "size", Vector2.new(self.origWidth + EXPAND, self.size.y), 0.2)
end

--- @registerMethod
function NavButton._OnMouseExited(self: NavButton)
    if self.tween then
        self.tween:Kill()
    end

    self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
        :TweenProperty(self, "size", Vector2.new(self.origWidth, self.size.y), 0.25)
end

return NavButtonC
