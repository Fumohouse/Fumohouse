local Billboard = require("../nodes/Billboard")
local Character = require("Character")

local NetworkManagerM = require("../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

--- @class
--- @extends Billboard
local Nametag = {}
local NametagC = gdclass(Nametag)

export type Nametag = Billboard.Billboard & typeof(Nametag) & {
    --- @property
    character: Character.Character,

    --- @property
    label: Label,
}

function Nametag._Ready(self: Nametag)
    Billboard._Ready(self)

    self.character.renamed:Connect(Callable.new(self, "UpdateName"))
    self:UpdateName()

    self.visible = NetworkManager.isActive
end

--- @registerMethod
function Nametag.UpdateName(self: Nametag)
    self.label.text = self.character.name
end

return NametagC
