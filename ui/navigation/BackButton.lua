local NavButton = require("NavButton")
local MenuUtils = require("MenuUtils.mod")

local BackButtonImpl = {}
local BackButton = gdclass(nil, NavButton)
    :RegisterImpl(BackButtonImpl)

export type BackButton = NavButton.NavButton & typeof(BackButtonImpl)

function BackButtonImpl.targetPos(self: BackButton, vis: boolean)
    if vis then
        return Vector2.new(0, self.position.y)
    else
        return Vector2.new(-self.size.x - MenuUtils.MARGIN, self.position.y)
    end
end

function BackButtonImpl.Hide(self: BackButton)
    self.modulate = Color.TRANSPARENT
    self.position = self:targetPos(false)
end

function BackButtonImpl.Transition(self: BackButton, vis: boolean)
    local tween = MenuUtils.CommonTween(self, vis)
    tween:TweenProperty(self, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self, "position", self:targetPos(vis), MenuUtils.TRANSITION_DURATION)
end

return BackButton
