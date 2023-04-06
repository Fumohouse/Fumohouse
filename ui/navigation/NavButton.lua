local NavButtonImpl = {}
local NavButton = gdclass(nil, Button)
    :RegisterImpl(NavButtonImpl)

export type NavButton = Button & typeof(NavButtonImpl) & {
    origWidth: number,

    tween: Tween?,
}

local EXPAND = 20

function NavButtonImpl.TransitionArgs(self: NavButton)
    return {
        inArgs = {},
        outArgs = { self:GetIndex() + 1 }
    }
end

function NavButtonImpl._Ready(self: NavButton)
    self.origWidth = self.size.x

    self.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    self.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
end

NavButton:RegisterMethod("_Ready")

function NavButtonImpl._OnMouseEntered(self: NavButton)
    if self.tween then
        self.tween:Kill()
    end

    self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.BACK)
        :TweenProperty(self, "size", Vector2.new(self.origWidth + EXPAND, self.size.y), 0.2)
end

NavButton:RegisterMethod("_OnMouseEntered")

function NavButtonImpl._OnMouseExited(self: NavButton)
    if self.tween then
        self.tween:Kill()
    end

    self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
        :TweenProperty(self, "size", Vector2.new(self.origWidth, self.size.y), 0.25)
end

NavButton:RegisterMethod("_OnMouseExited")

return NavButton
