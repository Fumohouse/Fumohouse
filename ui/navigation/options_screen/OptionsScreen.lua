local TransitionElement = require("../TransitionElement")
local ButtonTabContainer = require("../../../nodes/ButtonTabContainer")
local MenuUtils = require("../MenuUtils.mod")

local ConfigManagerM = require("../../../config/ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class
--- @extends TransitionElement
--- @permissions INTERNAL OS
local OptionsScreen = {}
local OptionsScreenC = gdclass(OptionsScreen)

--- @classType OptionsScreen
export type OptionsScreen = TransitionElement.TransitionElement & typeof(OptionsScreen) & {
    tabContainer: ButtonTabContainer.ButtonTabContainer,
    currentTab: Control?,
    tabs: Control,
    restartPrompt: Control,
}

--- @registerMethod
function OptionsScreen._OnSelectionChanged(self: OptionsScreen)
    if self.currentTab then
        self.currentTab.visible = false
    end

    local tabIdx = self.tabContainer.selection
    if tabIdx < 0 then
        self.currentTab = nil
        return
    end

    local tab = assert(self.tabs:GetChild(self.tabContainer.selection)) :: Control
    tab.visible = true
    self.currentTab = tab
end

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
    -- Tabs
    self.tabContainer = self:GetNode("%ButtonTabContainer") :: ButtonTabContainer.ButtonTabContainer
    self.tabs = self:GetNode("%Tabs") :: Control

    for _, child: Control in self.tabs:GetChildren() do
        child.visible = false
    end

    self.tabContainer.selection = 0
    self:_OnSelectionChanged()
    self.tabContainer.selectionChanged:Connect(Callable.new(self, "_OnSelectionChanged"))

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
