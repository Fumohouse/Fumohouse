local NavButton = require("NavButton")
local MenuUtils = require("MenuUtils.mod")

--- @class
--- @extends NavButton
local BackButton = {}
local BackButtonC = gdclass(BackButton)

--- @classType BackButton
export type BackButton = NavButton.NavButton & typeof(BackButton)

function BackButton.targetPos(self: BackButton, vis: boolean)
    if vis then
        return Vector2.new(0, self.position.y)
    else
        return Vector2.new(-self.size.x - MenuUtils.MARGIN, self.position.y)
    end
end

function BackButton.Hide(self: BackButton)
    self.modulate = Color.TRANSPARENT
    self.position = self:targetPos(false)
end

function BackButton.Show(self: BackButton)
    self.modulate = Color.WHITE
    self.position = self:targetPos(true)
end

function BackButton.Transition(self: BackButton, vis: boolean)
    local tween = MenuUtils.CommonTween(self, vis)
    tween:TweenProperty(self, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self, "position", self:targetPos(vis), MenuUtils.TRANSITION_DURATION)
end

return BackButtonC
