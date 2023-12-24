local NavMenu = require("../NavMenu")
local MenuUtils = require("../MenuUtils.mod")
local TransitionElement = require("../TransitionElement")
local MainScreen = require("MainScreen")
local NavButton = require("../NavButton")

--- @class
--- @extends NavMenu
--- @permissions INTERNAL
local MainMenu = {}
local MainMenuC = gdclass(MainMenu)

--- @classType MainMenu
export type MainMenu = NavMenu.NavMenu & typeof(MainMenu) & {
    mainScreen: MainScreen.MainScreen,
    infoScreen: TransitionElement.TransitionElement,
    optionsScreen: TransitionElement.TransitionElement,
    placeholderScreen: TransitionElement.TransitionElement,
    dim: ColorRect,
}

function MainMenu.Dim(self: MainMenu, vis: boolean)
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

--- @registerMethod
function MainMenu._OnExitButtonPressed(self: MainMenu, button: Button)
    self:SwitchScreen(nil, (button :: NavButton.NavButton):TransitionArgs())

    local dimTween = self:Dim(true)
    wait_signal(dimTween.finished)
    wait(0.1)

    self:GetTree():Quit()
end

function MainMenu._Ready(self: MainMenu)
    self.mainScreen = self:GetNode("Screens/MainScreen") :: MainScreen.MainScreen
    self.infoScreen = self:GetNode("Screens/InfoScreen") :: TransitionElement.TransitionElement
    self.optionsScreen = self:GetNode("Screens/OptionsScreen") :: TransitionElement.TransitionElement
    self.placeholderScreen = self:GetNode("Screens/PlaceholderScreen") :: TransitionElement.TransitionElement

    NavMenu._Ready(self)

    self.dim = self:GetNode("Dim") :: ColorRect

    local infoButton = self:GetNode("%InfoButton") :: NavButton.NavButton
    infoButton.pressed:Connect(Callable.new(self, "_OnScreenNavButtonPressed"):Bind(infoButton, self.infoScreen))

    local optionsButton = self:GetNode("%OptionsButton") :: NavButton.NavButton
    optionsButton.pressed:Connect(Callable.new(self, "_OnScreenNavButtonPressed"):Bind(optionsButton, self.optionsScreen))

    local exitButton = self:GetNode("%ExitButton") :: NavButton.NavButton
    exitButton.pressed:Connect(Callable.new(self, "_OnExitButtonPressed"):Bind(exitButton))

    for _, button: NavButton.NavButton in self.mainScreen.mainButtons:GetChildren() do
        -- TODO: this is very temporary
        if button.name ~= "InfoButton" and button.name ~= "OptionsButton" and button.name ~= "ExitButton" then
            button.pressed:Connect(Callable.new(self, "_OnScreenNavButtonPressed"):Bind(button, self.placeholderScreen))
        end
    end

    -- Setup
    wait(0.05)
    self:Dim(false)
    self:SwitchScreen(self.mainScreen)
end

return MainMenuC
