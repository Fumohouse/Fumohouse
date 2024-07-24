local ScreenBase = require("../ScreenBase")
local MapCard = require("MapCard")

local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local NetworkManagerM = require("../../../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

--- @class
--- @extends ScreenBase
local PlayScreen = {}
local PlayScreenC = gdclass(PlayScreen)

export type PlayScreen = ScreenBase.ScreenBase & typeof(PlayScreen) & {
    --- @property
    mapList: Control,

    --- @property
    addressInput: LineEdit,
    --- @property
    portInput: SpinBox,
    --- @property
    usernameInput: LineEdit,
    --- @property
    passwordInput: LineEdit,
    --- @property
    joinButton: Button,

    --- @property
    statusPopup: Control,
    --- @property
    statusHeading: Label,
    --- @property
    statusDetails: Label,
}

local mapCardScene: PackedScene = assert(load("map_card.tscn"))

--- @registerMethod
function PlayScreen._Ready(self: PlayScreen)
    ScreenBase._Ready(self)

    for id in MapManager.maps do
        local mapCard = mapCardScene:Instantiate() :: MapCard.MapCard
        mapCard.id = id

        self.mapList:AddChild(mapCard)
    end

    self.joinButton.pressed:Connect(Callable.new(self, "_OnJoinPressed"))

    local updateCb = Callable.new(self, "_OnSystemUpdate")
    MapManager.statusUpdate:Connect(updateCb)
    NetworkManager.statusUpdate:Connect(updateCb)
end

--- @registerMethod
function PlayScreen._OnJoinPressed(self: PlayScreen)
    local address = self.addressInput.text
    if address == "" then
        address = "127.0.0.1"
    end

    local port = self.portInput.value

    local username = self.usernameInput.text
    if username == "" then
        username = "Player" .. math.random(1, 1000)
    end

    local password = self.passwordInput.text

    NetworkManager:Join(address, port, username, password)

    self.joinButton.disabled = true
end

--- @registerMethod
function PlayScreen._OnSystemUpdate(self: PlayScreen, details: string, failure: boolean)
    self.statusPopup.visible = true
    self.statusDetails.text = details

    if failure then
        self.statusHeading.text = "Failed"

        wait(3)
        self.statusPopup.visible = false
        self.joinButton.disabled = false
    else
        self.statusHeading.text = "Please wait..."
    end
end

return PlayScreenC
