local NavMenu = require("../NavMenu")
local MenuUtils = require("../MenuUtils.mod")
local MenuScreen = require("MenuScreen")
local NavButton = require("../NavButton")
local TransitionElement = require("../TransitionElement")

local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

--- @class
--- @extends NavMenu
--- @permissions INTERNAL
local GameMenu = {}
local GameMenuC = gdclass(GameMenu)

export type GameMenu = NavMenu.NavMenu & typeof(GameMenu) & {
    --- @signal
    opened: Signal,

    --- @property
    mainScreen: MenuScreen.MenuScreen,
    --- @property
    infoScreen: TransitionElement.TransitionElement,
    --- @property
    optionsScreen: TransitionElement.TransitionElement,
    --- @property
    leaveScreen: TransitionElement.TransitionElement,

    --- @property
    continueButton: NavButton.NavButton,
    --- @property
    infoButton: NavButton.NavButton,
    --- @property
    optionsButton: NavButton.NavButton,
    --- @property
    leaveButton: NavButton.NavButton,

    blurBackground: Control,
    blurMat: ShaderMaterial,
    isVisible: boolean,
    isLeaving: boolean,

    oldMouseMode: ClassEnumInput_MouseMode?,
    tween: Tween?,
}

local BLUR_PARAM = "shader_parameter/blur"
local DIM_PARAM = "shader_parameter/dim"

function GameMenu.Hide(self: GameMenu)
    NavMenu.Hide(self)

    self.mouseFilter = Control.MouseFilter.IGNORE
    self.blurBackground.visible = false

    -- Godot dislikes tweening from 0 very much
    self.blurMat:Set(BLUR_PARAM, 0.001)
    self.blurMat:Set(DIM_PARAM, 0.001)

    self.isVisible = false
end

function GameMenu.Transition(self: GameMenu, vis: boolean, args: NavMenu.SwitchArgs?)
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

function GameMenu.Dismiss(self: GameMenu)
    if not self.continueButton.disabled then
        self:Transition(false)
    end
end

function GameMenu._UnhandledInput(self: GameMenu, event: InputEvent)
    if event:IsActionPressed("menu_back") and not self.isVisible then
        self:Transition(true)
        self:GetViewport():SetInputAsHandled()
        return
    end

    NavMenu._UnhandledInput(self, event)
end

--- @registerMethod
function GameMenu._OnMainScreenTransition(self: GameMenu, vis: boolean)
    if vis then
        if not self.isVisible and not self.isLeaving then
            self:Transition(true)
        end

        -- Input systems (e.g. character input) will check focus to avoid unwanted behavior
        self:GrabFocus()
    end
end

--- @registerMethod
function GameMenu._OnContinueButtonPressed(self: GameMenu, button: Button)
    self:Transition(false, (button :: NavButton.NavButton):TransitionArgs())
end

--- @registerMethod
function GameMenu._OnLeaveButtonPressed(self: GameMenu)
    self.isLeaving = true
    self.inhibitBack = true
    self:_OnScreenNavButtonPressed(self.leaveButton, self.leaveScreen)
    wait(0.5)
    MapManager:Leave()
end

function GameMenu._Ready(self: GameMenu)
    NavMenu._Ready(self)

    self.mainScreen.transition:Connect(Callable.new(self, "_OnMainScreenTransition"))

    self.blurBackground = self:GetNode("Blur") :: Control
    self.blurMat = assert(self.blurBackground.material) :: ShaderMaterial

    self.continueButton.pressed:Connect(Callable.new(self, "_OnContinueButtonPressed"):Bind(self.continueButton))
    self.infoButton.pressed:Connect(Callable.new(self, "_OnScreenNavButtonPressed"):Bind(self.infoButton, self.infoScreen))
    self.optionsButton.pressed:Connect(Callable.new(self, "_OnScreenNavButtonPressed"):Bind(self.optionsButton, self.optionsScreen))
    self.leaveButton.pressed:Connect(Callable.new(self, "_OnLeaveButtonPressed"))

    self:Hide()
end

return GameMenuC
