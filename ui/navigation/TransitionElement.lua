local MenuUtils = require("MenuUtils.mod")

--- @class
--- @extends Control
local TransitionElement = {}
local TransitionElementC = gdclass(TransitionElement)

--- @classType TransitionElement
export type TransitionElement = Control & typeof(TransitionElement)

function TransitionElement.Hide(self: TransitionElement)
    self.modulate = Color.TRANSPARENT
end

function TransitionElement.Show(self: TransitionElement)
    self.modulate = Color.WHITE
end

function TransitionElement.Transition(self: TransitionElement, vis: boolean, ...: any): Tween?
    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)

    tween:TweenProperty(self, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION)

    return tween
end

return TransitionElementC
