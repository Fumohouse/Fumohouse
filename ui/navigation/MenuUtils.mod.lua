local MenuUtils = {
    MARGIN = 5,
    TRANSITION_DURATION = 0.35,
}

function MenuUtils.CommonTween(self: Node, vis: boolean)
    return self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(if vis then Tween.TransitionType.CIRC else Tween.TransitionType.QUAD)
end

return MenuUtils
