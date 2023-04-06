local NavButton = require("NavButton")
local MenuUtils = require("MenuUtils.mod")

local NavButtonContainerImpl = {}
local NavButtonContainer = gdclass(nil, VBoxContainer)
    :RegisterImpl(NavButtonContainerImpl)

export type NavButtonContainer = VBoxContainer & typeof(NavButtonContainerImpl)

function NavButtonContainerImpl.buttonTargetPos(self: NavButtonContainer, button: NavButton.NavButton, vis: boolean)
    if vis then
        return Vector2.new(0, button.position.y)
    else
        return Vector2.new(-button.origWidth - MenuUtils.MARGIN, button.position.y)
    end
end

function NavButtonContainerImpl.Hide(self: NavButtonContainer)
    for _, button: NavButton.NavButton in self:GetChildren() do
        button.disabled = true
        button.position = self:buttonTargetPos(button, false)
        button.modulate = Color.TRANSPARENT
    end
end

function NavButtonContainerImpl.Transition(self: NavButtonContainer, vis: boolean, buttonIdx: number?)
    if vis then
        -- Wait for container to update position before overriding it and animating.
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

            coroutine.wrap(function()
                -- Reset position for next transition
                wait_signal(modTweener.finished)
                button.position = self:buttonTargetPos(button, false)
            end)()

            continue
        end

        local tweener = tween:Parallel():TweenProperty(button, "position", self:buttonTargetPos(button, vis), MenuUtils.TRANSITION_DURATION)

        if not buttonIdx or vis then
            tweener:SetDelay(0.03 * (i - 1))
        end
    end
end

return NavButtonContainer
