local MainMenuButtonImpl = {}
local MainMenuButton = gdclass(nil, Button)
    :RegisterImpl(MainMenuButtonImpl)

export type MainMenuButton = Button & typeof(MainMenuButtonImpl) & {
    origWidth: number,

    tween: Tween?,
}

local EXPAND = 20

function MainMenuButtonImpl._Ready(self: MainMenuButton)
    self.origWidth = self.size.x

    self.mouseEntered:Connect(Callable.new(self, "_OnMouseEntered"))
    self.mouseExited:Connect(Callable.new(self, "_OnMouseExited"))
end

MainMenuButton:RegisterMethod("_Ready")

function MainMenuButtonImpl._OnMouseEntered(self: MainMenuButton)
    if self.tween then
        self.tween:Kill()
    end

    self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.BACK)
        :TweenProperty(self, "size", Vector2.new(self.origWidth + EXPAND, self.size.y), 0.2)
end

MainMenuButton:RegisterMethod("_OnMouseEntered")

function MainMenuButtonImpl._OnMouseExited(self: MainMenuButton)
    if self.tween then
        self.tween:Kill()
    end

    self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)
        :TweenProperty(self, "size", Vector2.new(self.origWidth, self.size.y), 0.25)
end

MainMenuButton:RegisterMethod("_OnMouseExited")

return MainMenuButton
