local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

--- @class
--- @extends Control
--- @permissions INTERNAL
local MapCard = {}
local MapCardC = gdclass(MapCard)

export type MapCard = Control & typeof(MapCard) & {
    --- @property
    id: string,

    --- @property
    nameLabel: Label,
    --- @property
    versionLabel: Label,
    --- @property
    descriptionLabel: RichTextLabel,

    --- @property
    singleplayerButton: Button,
    --- @property
    multiplayerButton: Button,
}

--- @registerMethod
function MapCard._Ready(self: MapCard)
    local manifest = assert(MapManager.maps[self.id]).manifest

    self.nameLabel.text = manifest.name
    self.versionLabel.text = `v{manifest.version}`
    self.descriptionLabel.text = manifest.description

    self.singleplayerButton.pressed:Connect(Callable.new(self, "_OnSingleplayerButtonPressed"))
    self.multiplayerButton.pressed:Connect(Callable.new(self, "_OnMultiplayerButtonPressed"))
end

--- @registerMethod
function MapCard._OnSingleplayerButtonPressed(self: MapCard)
    MapManager:StartSingleplayer(self.id)
end

--- @registerMethod
function MapCard._OnMultiplayerButtonPressed(self: MapCard)
    MapManager:StartMultiplayerServer(self.id)
end

return MapCardC
