local MenuUtils = require("../MenuUtils.mod")
local MusicController = require("../../music_controller/MusicController")
local NavButtonContainer = require("../NavButtonContainer")
local TransitionElement = require("../TransitionElement")
local AppearanceManager = require("../../../character/appearance/AppearanceManager")

local AppearancesM = require("../../../character/appearance/Appearances")
local Appearances = gdglobal("Appearances") :: AppearancesM.Appearances

--- @class
--- @extends TransitionElement
local MainScreen = {}
local MainScreenC = gdclass(MainScreen)

--- @classType MainScreen
export type MainScreen = TransitionElement.TransitionElement & typeof(MainScreen) & {
    --- @property
    nonNavigation: Control,
    --- @property
    mainButtons: NavButtonContainer.NavButtonContainer,

    --- @property
    topBar: Control,

    --- @property
    versionLabel: Control,

    --- @property
    musicButton: Button,
    --- @property
    musicController: MusicController.MusicController,

    --- @property
    previewAppearanceManager: AppearanceManager.AppearanceManager,

    musicControllerTween: Tween?,
    musicControllerVisible: boolean,
}

--- @registerMethod
function MainScreen._OnMusicButtonPressed(self: MainScreen)
    self.musicController:Transition(not self.musicController.visible)
end

function MainScreen.topBarTargetPos(self: MainScreen, vis: boolean)
    if vis then
        return Vector2.new(self.topBar.position.x, 0)
    else
        return Vector2.new(self.topBar.position.x, -self.topBar.size.y - MenuUtils.MARGIN)
    end
end

function MainScreen.versionLabelTargetPos(self: MainScreen, vis: boolean)
    if vis then
        return Vector2.new(self.nonNavigation.size.x - self.versionLabel.size.x, self.versionLabel.position.y)
    else
        return Vector2.new(self.nonNavigation.size.x + MenuUtils.MARGIN, self.versionLabel.position.y)
    end
end

function MainScreen.Hide(self: MainScreen)
    self.nonNavigation.modulate = Color.TRANSPARENT
    self.mainButtons:Hide()
    self.topBar.position = self:topBarTargetPos(false)
    self.versionLabel.position = self:versionLabelTargetPos(false)
end

function MainScreen.Transition(self: MainScreen, vis: boolean, buttonIdx: number?): Tween?
    if not vis then
        -- Hide overlays
        self.musicController:Transition(false)
    else
        self.previewAppearanceManager:LoadAppearance()
    end

    local tween = MenuUtils.CommonTween(self, vis)
    local targetModulate = if vis then Color.WHITE else Color.TRANSPARENT

    tween:Parallel():TweenProperty(self.nonNavigation, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.topBar, "position", self:topBarTargetPos(vis), MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.versionLabel, "position", self:versionLabelTargetPos(vis), MenuUtils.TRANSITION_DURATION)

    self.mainButtons:Transition(vis, buttonIdx)

    return tween
end

--- @registerMethod
function MainScreen._Ready(self: MainScreen)
    self.musicController:Hide()
    self.musicButton.pressed:Connect(Callable.new(self, "_OnMusicButtonPressed"))

    self.previewAppearanceManager.appearance = Appearances.current
    self.previewAppearanceManager:LoadAppearance()
end

return MainScreenC
