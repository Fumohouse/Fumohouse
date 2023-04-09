local NavMenu = require("../NavMenu")
local MenuUtils = require("../MenuUtils.mod")
local MenuScreen = require("MenuScreen")
local NavButton = require("../NavButton")
local TransitionElement = require("../TransitionElement")

local GameMenuImpl = {}
local GameMenu = gdclass(nil, NavMenu)
    :RegisterImpl(GameMenuImpl)

export type GameMenu = NavMenu.NavMenu & typeof(GameMenuImpl) & {
    opened: Signal,

    mainScreen: MenuScreen.MenuScreen,
    optionsScreen: TransitionElement.TransitionElement,
    blurBackground: Control,
    blurMat: ShaderMaterial,
    isVisible: boolean,

    oldMouseMode: ClassEnumInput_MouseMode?,
    tween: Tween?,
}

GameMenu:RegisterSignal("opened")

local BLUR_PARAM = "shader_parameter/blur"
local DIM_PARAM = "shader_parameter/dim"

function GameMenuImpl.Hide(self: GameMenu)
    NavMenu.Hide(self)

    self.mouseFilter = Control.MouseFilter.IGNORE
    self.blurBackground.visible = false

    -- Godot dislikes tweening from 0 very much
    self.blurMat:Set(BLUR_PARAM, 0.001)
    self.blurMat:Set(DIM_PARAM, 0.001)

    self.isVisible = false
end

function GameMenuImpl.Transition(self: GameMenu, vis: boolean, args: NavMenu.SwitchArgs?)
    if vis then
        -- Allow connected nodes to adjust accordingly when menu is opened.
        -- Happens before input mode update due to things like CameraController (hold right click to move camera).
        self.opened:Emit()

        if not self.oldMouseMode then
            self.oldMouseMode = Input.singleton.mouseMode
        end
        Input.singleton.mouseMode = Input.MouseMode.VISIBLE
    else
        if self.oldMouseMode then
            Input.singleton.mouseMode = self.oldMouseMode
            self.oldMouseMode = nil
        end

        local focusOwner = self:GetViewport():GuiGetFocusOwner()
        -- TODO: Luau 570
        if focusOwner and (self :: Control == focusOwner or self:IsAncestorOf(focusOwner)) then
            focusOwner:ReleaseFocus()
        end
    end

    if self.tween then
        self.tween:Kill()
    end

    self.mouseFilter = if vis then Control.MouseFilter.STOP else Control.MouseFilter.IGNORE
    self.blurBackground.visible = true
    self:SwitchScreen(if vis then self.mainScreen else nil, args)

    local tween = MenuUtils.CommonTween(self, vis)
    tween:TweenProperty(self.blurMat, BLUR_PARAM, if vis then 1 else 0, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.blurMat, DIM_PARAM, if vis then 0.3 else 0, MenuUtils.TRANSITION_DURATION)

    if not vis then
        coroutine.wrap(function()
            if wait_signal(tween.finished) then
                self.blurBackground.visible = false
            end
        end)()
    end

    self.tween = tween
    self.isVisible = vis
end

function GameMenuImpl.Dismiss(self: GameMenu)
    self:Transition(false)
end

function GameMenuImpl._UnhandledInput(self: GameMenu, event: InputEvent)
    if Input.singleton:IsActionJustPressed("game_menu") and not self.isVisible then
        self:Transition(true)
        return
    end

    NavMenu._UnhandledInput(self, event)
end

function GameMenuImpl._OnMainScreenTransition(self: GameMenu, vis: boolean)
    if vis then
        -- Input systems (e.g. character input) will check focus to avoid unwanted behavior
        self:GrabFocus()
    end
end

GameMenu:RegisterMethodAST("_OnMainScreenTransition")

function GameMenuImpl._OnContinueButtonPressed(self: GameMenu, button: Button)
    self:Transition(false, (button :: NavButton.NavButton):TransitionArgs())
end

GameMenu:RegisterMethodAST("_OnContinueButtonPressed")

function GameMenuImpl._Ready(self: GameMenu)
    self.mainScreen = self:GetNode("Screens/MenuScreen") :: MenuScreen.MenuScreen
    self.mainScreen.transition:Connect(Callable.new(self, "_OnMainScreenTransition"))
    self.optionsScreen = self:GetNode("Screens/OptionsScreen") :: TransitionElement.TransitionElement
    NavMenu._Ready(self)

    self.blurBackground = self:GetNode("Blur") :: Control
    self.blurMat = assert(self.blurBackground.material) :: ShaderMaterial

    local optionsButton = self:GetNode("%OptionsButton") :: NavButton.NavButton
    optionsButton.pressed:Connect(Callable.new(self, "_OnScreenNavButtonPressed"):Bind(optionsButton, self.optionsScreen))

    local continueButton = self:GetNode("%ContinueButton") :: NavButton.NavButton
    continueButton.pressed:Connect(Callable.new(self, "_OnContinueButtonPressed"):Bind(continueButton))

    self:Hide()
end

GameMenu:RegisterMethod("_Ready")

return GameMenu
