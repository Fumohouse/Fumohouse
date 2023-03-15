local MainMenuConstants = require("MainMenuConstants.mod")
local MainScreen = require("MainScreen")

local MainMenuImpl = {}
local MainMenu = gdclass(nil, Control)
    :Permissions(Enum.Permissions.INTERNAL)
    :RegisterImpl(MainMenuImpl)

type MainMenuT = {
    mainScreen: MainScreen.MainScreen,
    backButton: Button,
    dim: ColorRect,
    placeholderScreen: Control,
}

export type MainMenu = Control & MainMenuT & typeof(MainMenuImpl)

-- Placeholder screen --

function MainMenuImpl.placeholderScreenTargetPos(self: MainMenu, vis: boolean)
    local defaultPos = (self.size - self.placeholderScreen.size) / 2 -- Center

    if vis then
        return defaultPos
    else
        return defaultPos + Vector2.DOWN * 100
    end
end

function MainMenuImpl.HidePlaceholderScreen(self: MainMenu)
    self.placeholderScreen.position = self:placeholderScreenTargetPos(false)
end

function MainMenuImpl.TransitionPlaceholderScreen(self: MainMenu, vis: boolean)
    self.placeholderScreen.visible = true

    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)


    tween:TweenProperty(self.placeholderScreen, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MainMenuConstants.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.placeholderScreen, "position", self:placeholderScreenTargetPos(vis), MainMenuConstants.TRANSITION_DURATION)

    coroutine.wrap(function()
        if not vis and wait_signal(tween.finished) then
            self.placeholderScreen.visible = false
        end
    end)()
end

-- Back Button --

function MainMenuImpl.backButtonTargetPos(self: MainMenu, vis: boolean)
    if vis then
        return Vector2.new(0, self.backButton.position.y)
    else
        return Vector2.new(-self.backButton.size.x - MainMenuConstants.MARGIN, self.backButton.position.y)
    end
end

function MainMenuImpl.HideBackButton(self: MainMenu)
    self.backButton.modulate = Color.TRANSPARENT
    self.backButton.position = self:backButtonTargetPos(false)
end

function MainMenuImpl.TransitionBackButton(self: MainMenu, vis: boolean)
    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)

    tween:TweenProperty(self.backButton, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MainMenuConstants.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.backButton, "position", self:backButtonTargetPos(vis), MainMenuConstants.TRANSITION_DURATION)
end

function MainMenuImpl._OnBackButtonPress(self: MainMenu)
    self.mainScreen:Transition(true)
    self:TransitionBackButton(false)

    self:TransitionPlaceholderScreen(false)
end

MainMenu:RegisterMethodAST("_OnBackButtonPress")

-- Dim --

function MainMenuImpl.Dim(self: MainMenu, vis: boolean)
    self.dim.visible = true

    local duration = if vis then 1.5 * MainMenuConstants.TRANSITION_DURATION else 0.5 * MainMenuConstants.TRANSITION_DURATION

    local tween = self:CreateTween()
    tween:TweenProperty(self.dim, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, duration)

    coroutine.wrap(function()
        if not vis and wait_signal(tween.finished) then
            self.dim.visible = false
        end
    end)()

    return tween
end

-- Main --

function MainMenuImpl._OnNavButtonPress(self: MainMenu, button: Button)
    self.mainScreen:Transition(false, button:GetIndex() + 1)
    self:TransitionBackButton(true)

    self:TransitionPlaceholderScreen(true)
end

MainMenu:RegisterMethodAST("_OnNavButtonPress")

function MainMenuImpl._OnExitButtonPress(self: MainMenu, button: Button)
    self.mainScreen:Transition(false, button:GetIndex() + 1)

    local dimTween = self:Dim(true)
    wait_signal(dimTween.finished)
    wait(0.1)

    self:GetTree():Quit()
end

MainMenu:RegisterMethodAST("_OnExitButtonPress")

function MainMenuImpl._Ready(self: MainMenu)
    self.mainScreen = self:GetNode("MainScreen") :: MainScreen.MainScreen

    -- Back
    self.backButton = self:GetNode("BackButton") :: Button
    self.backButton.visible = true -- Hidden in editor
    self:HideBackButton()

    self.backButton.pressed:Connect(Callable.new(self, "_OnBackButtonPress"))

    self.dim = self:GetNode("Dim") :: ColorRect

    -- Buttons
    for _, button: Button in self.mainScreen.mainButtons:GetChildren() do
        -- TODO: this is very temporary
        if button.name == "Exit" then
            button.pressed:Connect(Callable.new(self, "_OnExitButtonPress"):Bind(button))
        else
            button.pressed:Connect(Callable.new(self, "_OnNavButtonPress"):Bind(button))
        end
    end

    -- Placeholder screen
    self.placeholderScreen = self:GetNode("PlaceholderScreen") :: Control
    self:HidePlaceholderScreen()

    -- Setup
    self.mainScreen:Hide()
    wait(0.05)
    self:Dim(false)
    self.mainScreen:Transition(true)
end

MainMenu:RegisterMethod("_Ready")

return MainMenu
