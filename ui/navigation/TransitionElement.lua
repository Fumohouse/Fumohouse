local MenuUtils = require("MenuUtils.mod")

local TransitionElementImpl = {}
local TransitionElement = gdclass(nil, Control)
    :RegisterImpl(TransitionElementImpl)

export type TransitionElement = Control & typeof(TransitionElementImpl)

function TransitionElementImpl.Hide(self: TransitionElement)
    self.modulate = Color.TRANSPARENT
end

function TransitionElementImpl.Transition(self: TransitionElement, vis: boolean, ...: any): Tween?
    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)

    tween:TweenProperty(self, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION)

    return tween
end

return TransitionElement
