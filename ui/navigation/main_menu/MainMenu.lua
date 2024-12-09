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

export type MainMenu = NavMenu.NavMenu & typeof(MainMenu) & {
    --- @property
    --- @default true
    transitionIn: boolean,

    --- @property
    mainScreen: MainScreen.MainScreen,
    --- @property
    playScreen: TransitionElement.TransitionElement,
    --- @property
    infoScreen: TransitionElement.TransitionElement,
    --- @property
    optionsScreen: TransitionElement.TransitionElement,
    --- @property
    characterEditor: TransitionElement.TransitionElement,

    --- @property
    playButton: NavButton.NavButton,
    --- @property
    infoButton: NavButton.NavButton,
    --- @property
    optionsButton: NavButton.NavButton,
    --- @property
    exitButton: NavButton.NavButton,

    --- @property
    editButton: Button,

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

--- @registerMethod
function MainMenu._OnEditButtonPressed(self: MainMenu)
    self:SwitchScreen(self.characterEditor)
end

function MainMenu._Ready(self: MainMenu)
    NavMenu._Ready(self)

    self.dim = self:GetNode("Dim") :: ColorRect

    local navButtonCb = Callable.new(self, "_OnScreenNavButtonPressed")
    self.playButton.pressed:Connect(navButtonCb:Bind(self.playButton, self.playScreen))
    self.infoButton.pressed:Connect(navButtonCb:Bind(self.infoButton, self.infoScreen))
    self.optionsButton.pressed:Connect(navButtonCb:Bind(self.optionsButton, self.optionsScreen))

    self.exitButton.pressed:Connect(Callable.new(self, "_OnExitButtonPressed"):Bind(self.exitButton))

    self.editButton.pressed:Connect(Callable.new(self, "_OnEditButtonPressed"))

    -- Setup
    if self.transitionIn then
        wait(0.05)
        self:Dim(false)
        self:SwitchScreen(self.mainScreen)
    end
end

return MainMenuC
