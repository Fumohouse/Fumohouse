local MenuUtils = require("../MenuUtils.mod")
local MusicController = require("../../music_controller/MusicController")
local NavButtonContainer = require("../NavButtonContainer")
local TransitionElement = require("../TransitionElement")

local MainScreenImpl = {}
local MainScreen = gdclass(nil, TransitionElement)
    :RegisterImpl(MainScreenImpl)

export type MainScreen = TransitionElement.TransitionElement & typeof(MainScreenImpl) & {
    nonNavigation: Control,
    mainButtons: NavButtonContainer.NavButtonContainer,

    topBar: Control,

    versionLabel: Control,

    musicController: MusicController.MusicController,
    musicControllerTween: Tween?,
    musicControllerVisible: boolean,
}

function MainScreenImpl._OnMusicButtonPressed(self: MainScreen)
    self.musicController:Transition(not self.musicController.visible)
end

MainScreen:RegisterMethod("_OnMusicButtonPressed")

function MainScreenImpl.topBarTargetPos(self: MainScreen, vis: boolean)
    if vis then
        return Vector2.new(self.topBar.position.x, 0)
    else
        return Vector2.new(self.topBar.position.x, -self.topBar.size.y - MenuUtils.MARGIN)
    end
end

function MainScreenImpl.versionLabelTargetPos(self: MainScreen, vis: boolean)
    if vis then
        return Vector2.new(self.nonNavigation.size.x - self.versionLabel.size.x, self.versionLabel.position.y)
    else
        return Vector2.new(self.nonNavigation.size.x + MenuUtils.MARGIN, self.versionLabel.position.y)
    end
end

function MainScreenImpl.Hide(self: MainScreen)
    self.nonNavigation.modulate = Color.TRANSPARENT
    self.mainButtons:Hide()
    self.topBar.position = self:topBarTargetPos(false)
    self.versionLabel.position = self:versionLabelTargetPos(false)
end

function MainScreenImpl.Transition(self: MainScreen, vis: boolean, buttonIdx: number?): Tween?
    if not vis then
        -- Hide overlays
        self.musicController:Transition(false)
    end

    local tween = MenuUtils.CommonTween(self, vis)
    local targetModulate = if vis then Color.WHITE else Color.TRANSPARENT

    tween:Parallel():TweenProperty(self.nonNavigation, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.topBar, "position", self:topBarTargetPos(vis), MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.versionLabel, "position", self:versionLabelTargetPos(vis), MenuUtils.TRANSITION_DURATION)

    self.mainButtons:Transition(vis, buttonIdx)

    return tween
end

function MainScreenImpl._Ready(self: MainScreen)
    self.nonNavigation = self:GetNode("NonNavigation") :: Control
    self.mainButtons = self:GetNode("MainButtons") :: NavButtonContainer.NavButtonContainer
    self.topBar = self:GetNode("NonNavigation/TopBar") :: Control
    self.versionLabel = self:GetNode("NonNavigation/VersionLabel") :: Control

    self.musicController = self:GetNode("MusicController") :: MusicController.MusicController
    self.musicController:Hide()

    local musicButton = self:GetNode("%MusicButton") :: Button
    musicButton.pressed:Connect(Callable.new(self, "_OnMusicButtonPressed"))
end

MainScreen:RegisterMethod("_Ready")

return MainScreen
