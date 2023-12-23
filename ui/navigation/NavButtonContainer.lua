local NavButton = require("NavButton")
local MenuUtils = require("MenuUtils.mod")

--- @class
--- @extends VBoxContainer
local NavButtonContainer = {}
local NavButtonContainerC = gdclass(NavButtonContainer)

--- @classType NavButtonContainer
export type NavButtonContainer = VBoxContainer & typeof(NavButtonContainer) & {
    tween: Tween?
}

function NavButtonContainer.buttonTargetX(self: NavButtonContainer, button: NavButton.NavButton, vis: boolean)
    return if vis then 0 else -button.origWidth - MenuUtils.MARGIN
end

function NavButtonContainer.Hide(self: NavButtonContainer)
    for _, button: NavButton.NavButton in self:GetChildren() do
        button.disabled = true
        button.position = Vector2.new(self:buttonTargetX(button, false), button.position.y)
        button.modulate = Color.TRANSPARENT
    end
end

function NavButtonContainer.Transition(self: NavButtonContainer, vis: boolean, buttonIdx: number?)
    if self.tween then
        self.tween:Kill()
    end

    if vis then
        -- Wait for container to update position before overriding it and animating.
        -- Wait two frames since MessageQueue is flushed after the signal is fired (??).
        wait_signal(self:GetTree().processFrame)
        wait_signal(self:GetTree().processFrame)
        self:Hide()
    end

    local tween = MenuUtils.CommonTween(self, vis)
    local targetModulate = if vis then Color.WHITE else Color.TRANSPARENT

    for i: number, button: NavButton.NavButton in self:GetChildren() do
        button.disabled = not vis

        local modTweener = tween:Parallel():TweenProperty(button, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)

        if i == buttonIdx and not vis then
            modTweener:SetDelay(0.1)
            continue
        end

        local tweener = tween:Parallel():TweenProperty(button, "position:x", self:buttonTargetX(button, vis), MenuUtils.TRANSITION_DURATION)

        if not buttonIdx or vis then
            tweener:SetDelay(0.03 * i)
        end
    end

    self.tween = tween
end

return NavButtonContainerC
