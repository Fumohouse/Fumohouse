local NavMenu = require("../NavMenu")
local MenuUtils = require("../MenuUtils.mod")
local TransitionElement = require("../TransitionElement")
local MainScreen = require("MainScreen")
local NavButton = require("../NavButton")

local MainMenuImpl = {}
local MainMenu = gdclass(nil, NavMenu)
    :Permissions(Enum.Permissions.INTERNAL)
    :RegisterImpl(MainMenuImpl)

export type MainMenu = NavMenu.NavMenu & typeof(MainMenuImpl) & {
    mainScreen: MainScreen.MainScreen,
    placeholderScreen: TransitionElement.TransitionElement,
    dim: ColorRect,
}

function MainMenuImpl.Dim(self: MainMenu, vis: boolean)
    self.dim.visible = true

    local duration = if vis then 1.5 * MenuUtils.TRANSITION_DURATION else 0.5 * MenuUtils.TRANSITION_DURATION

    local tween = self:CreateTween()
    tween:TweenProperty(self.dim, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, duration)

    coroutine.wrap(function()
        if not vis and wait_signal(tween.finished) then
            self.dim.visible = false
        end
    end)()

    return tween
end

function MainMenuImpl._OnNavButtonPress(self: MainMenu, button: Button)
    self:SwitchScreen(self.placeholderScreen, (button :: NavButton.NavButton):TransitionArgs())
end

MainMenu:RegisterMethodAST("_OnNavButtonPress")

function MainMenuImpl._OnExitButtonPress(self: MainMenu, button: Button)
    self:SwitchScreen(nil, (button :: NavButton.NavButton):TransitionArgs())

    local dimTween = self:Dim(true)
    wait_signal(dimTween.finished)
    wait(0.1)

    self:GetTree():Quit()
end

MainMenu:RegisterMethodAST("_OnExitButtonPress")

function MainMenuImpl._Ready(self: MainMenu)
    self.mainScreen = self:GetNode("Screens/MainScreen") :: MainScreen.MainScreen
    self.placeholderScreen = self:GetNode("Screens/PlaceholderScreen") :: TransitionElement.TransitionElement

    NavMenu._Ready(self)

    self.dim = self:GetNode("Dim") :: ColorRect

    local exitButton = self:GetNode("%ExitButton") :: NavButton.NavButton
    exitButton.pressed:Connect(Callable.new(self, "_OnExitButtonPress"):Bind(exitButton))

    for _, button: NavButton.NavButton in self.mainScreen.mainButtons:GetChildren() do
        -- TODO: this is very temporary
        if button.name ~= "ExitButton" then
            button.pressed:Connect(Callable.new(self, "_OnNavButtonPress"):Bind(button))
        end
    end

    -- Setup
    wait(0.05)
    self:Dim(false)
    self:SwitchScreen(self.mainScreen)
end

return MainMenu
