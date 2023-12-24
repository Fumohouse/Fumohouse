local ScreenBase = require('../ScreenBase')
local MenuUtils = require("../MenuUtils.mod")

local ConfigManagerM = require("../../../config/ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class
--- @extends ScreenBase
--- @permissions INTERNAL OS
local OptionsScreen = {}
local OptionsScreenC = gdclass(OptionsScreen)

--- @classType OptionsScreen
export type OptionsScreen = ScreenBase.ScreenBase & typeof(OptionsScreen) & {
    tabs: Control,
    restartPrompt: Control,
}

function OptionsScreen.restartPromptTargetPos(self: OptionsScreen, vis: boolean)
    if vis then
        return Vector2.new(self.restartPrompt.position.x, self.size.y - self.restartPrompt.size.y)
    else
        return Vector2.new(self.restartPrompt.position.x, self.size.y + MenuUtils.MARGIN)
    end
end

function OptionsScreen.HideRestartPrompt(self: OptionsScreen)
    self.restartPrompt.visible = false
    self.restartPrompt.position = self:restartPromptTargetPos(false)
end

function OptionsScreen.TransitionRestartPrompt(self: OptionsScreen, vis: boolean)
    self.restartPrompt.visible = true

    local tween = MenuUtils.CommonTween(self, vis)
    tween:TweenProperty(self.restartPrompt, "position", self:restartPromptTargetPos(vis), MenuUtils.TRANSITION_DURATION)

    if not vis then
        coroutine.wrap(function()
            if wait_signal(tween.finished) then
                self.restartPrompt.visible = false
            end
        end)()
    end
end

--- @registerMethod
function OptionsScreen._OnRestartRequired(self: OptionsScreen)
    self:TransitionRestartPrompt(true)
end

--- @registerMethod
function OptionsScreen._OnRestartPromptCancelPressed(self: OptionsScreen)
    self:TransitionRestartPrompt(false)
end

--- @registerMethod
function OptionsScreen._OnRestartPromptRestartPressed(self: OptionsScreen)
    OS.singleton:SetRestartOnExit(true, OS.singleton:GetCmdlineArgs())
    self:GetTree():Quit()
end

--- @registerMethod
function OptionsScreen._Ready(self: OptionsScreen)
    ScreenBase._Ready(self)

    -- Restart Prompt
    self.restartPrompt = self:GetNode("RestartPrompt") :: Control
    self:HideRestartPrompt()

    local restartCancelButton = self:GetNode("%RestartCancelButton") :: Button
    restartCancelButton.pressed:Connect(Callable.new(self, "_OnRestartPromptCancelPressed"))

    local restartRestartButton = self:GetNode("%RestartRestartButton") :: Button
    restartRestartButton.pressed:Connect(Callable.new(self, "_OnRestartPromptRestartPressed"))

    -- ConfigManager
    ConfigManager.restartRequired:Connect(Callable.new(self, "_OnRestartRequired"))
end

return OptionsScreenC
