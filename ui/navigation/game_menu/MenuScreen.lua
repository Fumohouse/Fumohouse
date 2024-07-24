local TransitionElement = require("../TransitionElement")
local NavButtonContainer = require("../NavButtonContainer")
local NavMenu = require("../NavMenu")
local NavButton = require("../NavButton")
local MenuUtils = require("../MenuUtils.mod")
local MusicController = require("../../music_controller/MusicController")

local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local NetworkManagerM = require("../../../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

--- @class
--- @extends TransitionElement
local MenuScreen = {}
local MenuScreenC = gdclass(MenuScreen)

export type MenuScreen = TransitionElement.TransitionElement & typeof(MenuScreen) & {
    --- @signal
    transition: SignalWithArgs<(vis: boolean) -> ()>,

    --- @property
    gameMenu: NavMenu.NavMenu,

    --- @property
    gradientBackground: Control,
    --- @property
    title: Control,
    --- @property
    navButtons: NavButtonContainer.NavButtonContainer,
    --- @property
    bottomBar: Control,
    --- @property
    musicController: MusicController.MusicController,

    --- @property
    continueButton: NavButton.NavButton,

    --- @property
    statusPopup: Control,
    --- @property
    statusHeading: Label,
    --- @property
    statusDetails: Label,
}

function MenuScreen.bottomBarTargetPos(self: MenuScreen, vis: boolean)
    if vis then
        return Vector2.new(self.bottomBar.position.x, self.size.y - self.bottomBar.size.y)
    else
        return Vector2.new(self.bottomBar.position.x, self.size.y)
    end
end

function MenuScreen.Hide(self: MenuScreen)
    self.gradientBackground.modulate = Color.TRANSPARENT
    self.title.modulate = Color.TRANSPARENT
    self.navButtons:Hide()
    self.bottomBar.modulate = Color.TRANSPARENT
    self.bottomBar.position = self:bottomBarTargetPos(false)
    self.musicController:Hide()
end

function MenuScreen.Transition(self: MenuScreen, vis: boolean, buttonIdx: number?): Tween?
    local tween = MenuUtils.CommonTween(self, vis)
    local targetModulate = if vis then Color.WHITE else Color.TRANSPARENT

    tween:TweenProperty(self.gradientBackground, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.title, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.bottomBar, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.statusPopup, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.bottomBar, "position", self:bottomBarTargetPos(vis), MenuUtils.TRANSITION_DURATION)

    self.navButtons:Transition(vis, buttonIdx)
    self.musicController:Transition(vis)

    self.transition:Emit(vis)

    self.continueButton.disabled = self.statusPopup.visible

    return tween
end

--- @registerMethod
function MenuScreen._OnNetworkManagerUpdate(self: MenuScreen, details: string, failure: boolean)
    if not failure then
        return
    end

    self.statusPopup.visible = true
    self.statusHeading.text = "Disconnected"
    self.statusDetails.text = details

    self:Transition(true)
end

--- @registerMethod
function MenuScreen._Ready(self: MenuScreen)
    local mapName = self.bottomBar:GetNode("MapName") :: Label
    local currentMap = MapManager.currentMap
    local name = if currentMap then currentMap.manifest.name else "???"
    local author = if currentMap then currentMap.manifest.author else "???"
    mapName.text = string.format("%s • %s", name, author)

    NetworkManager.statusUpdate:Connect(Callable.new(self, "_OnNetworkManagerUpdate"))
end

return MenuScreenC
