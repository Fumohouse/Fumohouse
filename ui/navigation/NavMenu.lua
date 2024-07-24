local BackButton = require("BackButton")
local TransitionElement = require("TransitionElement")
local NavButton = require("NavButton")

--- @class
--- @extends Control
local NavMenu = {}
local NavMenuC = gdclass(NavMenu)

export type NavMenu = Control & typeof(NavMenu) & {
    mainScreen: TransitionElement.TransitionElement?,
    currentScreen: TransitionElement.TransitionElement?,
    backButton: BackButton.BackButton,
    inhibitBack: boolean,

    -- "screenIn" is currentScreen
    tweenIn: Tween?,
    screenOut: TransitionElement.TransitionElement?,
    tweenOut: Tween?,
}

function NavMenu.HideScreen(screen: TransitionElement.TransitionElement)
    screen:Hide()
    screen.visible = false
end

function NavMenu.transitionScreen(screen: TransitionElement.TransitionElement, vis: boolean, ...: any)
    screen.visible = true

    local tween = screen:Transition(vis, ...)
    if tween and not vis then
        coroutine.wrap(function()
            if wait_signal(tween.finished) then
                NavMenu.HideScreen(screen)
                screen.visible = false
            end
        end)()
    end

    return tween
end

function NavMenu.Hide(self: NavMenu)
    if self.currentScreen then
        NavMenu.HideScreen(self.currentScreen)
        self.currentScreen = nil
    end
end

export type SwitchArgs = {
    inArgs: {any},
    outArgs: {any},
}

function NavMenu.SwitchScreen(self: NavMenu, screen: TransitionElement.TransitionElement?, args: SwitchArgs?)
    if self.currentScreen == screen then
        return
    end

    if self.screenOut and self.tweenOut and self.tweenIn then
        -- Prevent hiding due to wait_signal when switching too quickly
        NavMenu.HideScreen(self.screenOut)
        self.tweenOut:Kill()
        self.tweenIn:Kill()
    end

    self.screenOut = self.currentScreen
    if self.currentScreen then
        if args then
            self.tweenOut = NavMenu.transitionScreen(self.currentScreen, false, table.unpack(args.outArgs))
        else
            self.tweenOut = NavMenu.transitionScreen(self.currentScreen, false)
        end
    end

    -- TODO: Luau 570
    local notMainScreen = screen ~= nil and self.mainScreen ~= nil and screen :: Control ~= self.mainScreen :: Control

    if screen then
        if notMainScreen then
            self.backButton:GrabFocus()
        end

        if args then
            self.tweenIn = NavMenu.transitionScreen(screen, true, table.unpack(args.inArgs))
        else
            self.tweenIn = NavMenu.transitionScreen(screen, true)
        end
    end

    if not self.inhibitBack then
        self.backButton:Transition(notMainScreen)
    end

    self.currentScreen = screen
end

function NavMenu.SetScreen(self: NavMenu, screen: TransitionElement.TransitionElement?)
    if self.currentScreen then
        self:Hide()
    end

    self.currentScreen = screen

    if screen then
        screen.visible = true
        screen:Show()
        self.backButton:Show()
    end
end

--- @registerMethod
function NavMenu._OnBackButtonPress(self: NavMenu)
    if not self.inhibitBack then
        self:SwitchScreen(assert(self.mainScreen))
    end
end

function NavMenu.Dismiss(self: NavMenu)
end

--- @registerMethod
function NavMenu._UnhandledInput(self: NavMenu, event: InputEvent)
    -- Checking IsPressed prevents GameMenu from closing and opening again on (very) quick presses to menu_back
    if not self.inhibitBack and event:IsActionPressed("menu_back") then
        local focus = self:GetViewport():GuiGetFocusOwner()
        if focus and focus:HasMeta("blockDismiss") and focus:GetMeta("blockDismiss") == true then
            return
        end

        -- TODO: Luau 570: WTF
        if self.currentScreen and self.mainScreen and self.currentScreen:GetInstanceId() ~= self.mainScreen:GetInstanceId() then
            self:SwitchScreen(self.mainScreen)
        else
            self:Dismiss()
        end

        self:GetViewport():SetInputAsHandled()
    end
end

--- @registerMethod
function NavMenu._OnScreenNavButtonPressed(self: NavMenu, button: Button, screen: Control)
    self:SwitchScreen(screen :: TransitionElement.TransitionElement, (button :: NavButton.NavButton):TransitionArgs())
end

--- @registerMethod
function NavMenu._Ready(self: NavMenu)
    -- Inheriters shoulld set this before calling super _Ready
    self.backButton = self:GetNode("BackButton") :: BackButton.BackButton
    self.backButton.visible = true -- Hidden in editor
    self.backButton:Hide()

    self.backButton.pressed:Connect(Callable.new(self, "_OnBackButtonPress"))

    local screens = self:GetNode("Screens") :: Control
    for _, child: TransitionElement.TransitionElement in screens:GetChildren() do
        NavMenu.HideScreen(child)
    end
end

return NavMenuC
