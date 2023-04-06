local BackButton = require("BackButton")
local TransitionElement = require("TransitionElement")

local NavMenuImpl = {}
local NavMenu = gdclass(nil, Control)
    :RegisterImpl(NavMenuImpl)

export type NavMenu = Control & typeof(NavMenuImpl) & {
    mainScreen: TransitionElement.TransitionElement?,
    currentScreen: TransitionElement.TransitionElement?,
    backButton: BackButton.BackButton,

    -- "screenIn" is currentScreen
    tweenIn: Tween?,
    screenOut: TransitionElement.TransitionElement?,
    tweenOut: Tween?,
}

function NavMenuImpl.HideScreen(screen: TransitionElement.TransitionElement)
    screen:Hide()
    screen.visible = false
end

function NavMenuImpl.transitionScreen(screen: TransitionElement.TransitionElement, vis: boolean, ...: any)
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

function NavMenuImpl.Hide(self: NavMenu)
    if self.currentScreen then
        NavMenu.HideScreen(self.currentScreen)
        self.currentScreen = nil
    end
end

export type SwitchArgs = {
    inArgs: {any},
    outArgs: {any},
}

function NavMenuImpl.SwitchScreen(self: NavMenu, screen: TransitionElement.TransitionElement?, args: SwitchArgs?)
    if self.currentScreen == screen then
        return
    end

    if self.screenOut and self.tweenOut and self.tweenIn then
        -- Prevent hiding due to wait_signal when switching too quickly
        self.screenOut:Hide()
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

    if screen then
        if args then
            self.tweenIn = NavMenu.transitionScreen(screen, true, table.unpack(args.inArgs))
        else
            self.tweenIn = NavMenu.transitionScreen(screen, true)
        end
    end

    -- TODO: Luau 570: WTF
    self.backButton:Transition(screen ~= nil and self.mainScreen ~= nil and screen:GetInstanceId() ~= self.mainScreen:GetInstanceId())

    self.currentScreen = screen
end

function NavMenuImpl._OnBackButtonPress(self: NavMenu)
    self:SwitchScreen(assert(self.mainScreen))
end

NavMenu:RegisterMethod("_OnBackButtonPress")

function NavMenuImpl.Dismiss(self: NavMenu)
end

function NavMenuImpl._UnhandledInput(self: NavMenu, event: InputEvent)
    if Input.singleton:IsActionJustPressed("menu_back") then
        -- TODO: Luau 570: WTF
        if self.currentScreen and self.mainScreen and self.currentScreen:GetInstanceId() ~= self.mainScreen:GetInstanceId() then
            self:SwitchScreen(self.mainScreen)
        else
            self:Dismiss()
        end
    end
end

NavMenu:RegisterMethodAST("_UnhandledInput")

function NavMenuImpl._Ready(self: NavMenu)
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

NavMenu:RegisterMethod("_Ready")

return NavMenu
