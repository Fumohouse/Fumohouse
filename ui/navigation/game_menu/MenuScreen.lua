local TransitionElement = require("../TransitionElement")
local NavButtonContainer = require("../NavButtonContainer")
local MenuUtils = require("../MenuUtils.mod")
local MusicController = require("../../music_controller/MusicController")

local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local MenuScreenImpl = {}
local MenuScreen = gdclass(nil, TransitionElement)
    :RegisterImpl(MenuScreenImpl)

export type MenuScreen = TransitionElement.TransitionElement & typeof(MenuScreenImpl) & {
    gradientBackground: Control,
    title: Control,
    navButtons: NavButtonContainer.NavButtonContainer,
    bottomBar: Control,
    musicController: MusicController.MusicController,
}

function MenuScreenImpl.bottomBarTargetPos(self: MenuScreen, vis: boolean)
    if vis then
        return Vector2.new(self.bottomBar.position.x, self.size.y - self.bottomBar.size.y)
    else
        return Vector2.new(self.bottomBar.position.x, self.size.y)
    end
end

function MenuScreenImpl.Hide(self: MenuScreen)
    self.gradientBackground.modulate = Color.TRANSPARENT
    self.title.modulate = Color.TRANSPARENT
    self.navButtons:Hide()
    self.bottomBar.modulate = Color.TRANSPARENT
    self.bottomBar.position = self:bottomBarTargetPos(false)
    self.musicController:Hide()
end

function MenuScreenImpl.Transition(self: MenuScreen, vis: boolean, buttonIdx: number?): Tween?
    local tween = MenuUtils.CommonTween(self, vis)
    local targetModulate = if vis then Color.WHITE else Color.TRANSPARENT

    tween:TweenProperty(self.gradientBackground, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.title, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.bottomBar, "modulate", targetModulate, MenuUtils.TRANSITION_DURATION)
    tween:Parallel():TweenProperty(self.bottomBar, "position", self:bottomBarTargetPos(vis), MenuUtils.TRANSITION_DURATION)

    self.navButtons:Transition(vis, buttonIdx)
    self.musicController:Transition(vis)

    return tween
end

function MenuScreenImpl._Ready(self: MenuScreen)
    self.gradientBackground = self:GetNode("GradientBackground") :: Control
    self.title = self:GetNode("%Title") :: Control
    self.navButtons = self:GetNode("%NavButtonContainer") :: NavButtonContainer.NavButtonContainer
    self.bottomBar = self:GetNode("BottomBar") :: Control
    self.musicController = self:GetNode("MusicController") :: MusicController.MusicController

    local mapName = self.bottomBar:GetNode("MapName") :: Label
    local currentMap = MapManager.currentMap
    local name = if currentMap then currentMap.name else "???"
    local author = if currentMap then currentMap.author else "???"
    mapName.text = string.format("%s • %s", name, author)
end

MenuScreen:RegisterMethod("_Ready")

return MenuScreen
