local MainMenuConstants = require("MainMenuConstants.mod")
local MainMenuButton = require("MainMenuButton")

local MainScreenImpl = {}
local MainScreen = gdclass(nil, Control)
    :RegisterImpl(MainScreenImpl)

type MainScreenT = {
    nonNavigation: Control,
    mainButtons: Control,

    topBar: Control,

    versionLabel: Control,

    musicController: Control,
    musicControllerTween: Tween?,
    musicControllerVisible: boolean,
}

export type MainScreen = Control & MainScreenT & typeof(MainScreenImpl)

-- MusicController --

function MainScreenImpl.HideMusicController(self: MainScreen)
    self.musicController.scale = Vector2.new(0, 1)
    self.musicController.visible = false
end

function MainScreenImpl.TransitionMusicController(self: MainScreen, vis: boolean)
    if self.musicControllerTween then
        self.musicControllerTween:Kill()
    end

    self.musicController.visible = true

    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(Tween.TransitionType.QUAD)

    tween:TweenProperty(self.musicController, "scale", if vis then Vector2.ONE else Vector2.new(0, 1), MainMenuConstants.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.musicController, "modulate", if vis then Color.WHITE else Color.TRANSPARENT, MainMenuConstants.TRANSITION_DURATION)

    self.musicControllerTween = tween

    coroutine.wrap(function()
        if not vis and wait_signal(tween.finished) then
            self.musicController.visible = false
        end
    end)()
end

function MainScreenImpl._OnMusicButtonPressed(self: MainScreen)
    self:TransitionMusicController(not self.musicController.visible)
end

MainScreen:RegisterMethod("_OnMusicButtonPressed")

-- Main Transition --

function MainScreenImpl.buttonTargetPos(self: MainScreen, button: MainMenuButton.MainMenuButton, vis: boolean)
    if vis then
        return Vector2.new(0, button.position.y)
    else
        return Vector2.new(-button.origWidth - MainMenuConstants.MARGIN, button.position.y)
    end
end

function MainScreenImpl.topBarTargetPos(self: MainScreen, vis: boolean)
    if vis then
        return Vector2.new(self.topBar.position.x, 0)
    else
        return Vector2.new(self.topBar.position.x, -self.topBar.size.y - MainMenuConstants.MARGIN)
    end
end

function MainScreenImpl.versionLabelTargetPos(self: MainScreen, vis: boolean)
    if vis then
        return Vector2.new(self.nonNavigation.size.x - self.versionLabel.size.x, self.versionLabel.position.y)
    else
        return Vector2.new(self.nonNavigation.size.x + MainMenuConstants.MARGIN, self.versionLabel.position.y)
    end
end

function MainScreenImpl.Hide(self: MainScreen)
    self.nonNavigation.modulate = Color.TRANSPARENT

    for _, button: MainMenuButton.MainMenuButton in self.mainButtons:GetChildren() do
        button.disabled = true
        button.position = self:buttonTargetPos(button, false)
        button.modulate = Color.TRANSPARENT
    end

    self.topBar.position = self:topBarTargetPos(false)
    self.versionLabel.position = self:versionLabelTargetPos(false)
end

function MainScreenImpl.Transition(self: MainScreen, vis: boolean, buttonIdx: number?)
    if not vis then
        -- Hide overlays
        self:TransitionMusicController(false)
    end

    local tween = self:CreateTween()
        :SetEase(Tween.EaseType.OUT)
        :SetTrans(if vis then Tween.TransitionType.CIRC else Tween.TransitionType.QUAD)

    local targetModulate = if vis then Color.WHITE else Color.TRANSPARENT
    tween:Parallel():TweenProperty(self.nonNavigation, "modulate", targetModulate, MainMenuConstants.TRANSITION_DURATION)

    for i: number, button: MainMenuButton.MainMenuButton in self.mainButtons:GetChildren() do
        button.disabled = not vis

        local modTweener = tween:Parallel():TweenProperty(button, "modulate", targetModulate, MainMenuConstants.TRANSITION_DURATION)

        if i == buttonIdx and not vis then
            modTweener:SetDelay(0.1)

            coroutine.wrap(function()
                -- Reset position for next transition
                wait_signal(modTweener.finished)
                button.position = self:buttonTargetPos(button, false)
            end)()

            continue
        end

        local tweener = tween:Parallel():TweenProperty(button, "position", self:buttonTargetPos(button, vis), MainMenuConstants.TRANSITION_DURATION)

        if not buttonIdx or vis then
            tweener:SetDelay(0.04 * (i - 1))
        end
    end

    tween:Parallel():TweenProperty(self.topBar, "position", self:topBarTargetPos(vis), MainMenuConstants.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.versionLabel, "position", self:versionLabelTargetPos(vis), MainMenuConstants.TRANSITION_DURATION)
end

function MainScreenImpl._Ready(self: MainScreen)
    self.nonNavigation = self:GetNode("NonNavigation") :: Control
    self.mainButtons = self:GetNode("MainButtons") :: Control
    self.topBar = self:GetNode("NonNavigation/TopBar") :: Control
    self.versionLabel = self:GetNode("NonNavigation/VersionLabel") :: Control

    -- MusicController
    self.musicController = self:GetNode("MusicController") :: Control
    self:HideMusicController()

    local musicButton = self:GetNode("%MusicButton") :: Button
    musicButton.pressed:Connect(Callable.new(self, "_OnMusicButtonPressed"))
end

MainScreen:RegisterMethod("_Ready")

return MainScreen
