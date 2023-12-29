local ViewportInput = require("../../nodes/ViewportInput")
local AppearanceManager = require("../../character/appearance/AppearanceManager")

--- @class
--- @extends ViewportInput
local CharacterViewport = {}
local CharacterViewportC = gdclass(CharacterViewport)

--- @classType CharacterViewport
export type CharacterViewport = TextureRect & ViewportInput.ViewportInput & typeof(CharacterViewport) & {
    --- @property
    appearance: AppearanceManager.AppearanceManager,

    --- @property
    --- @range 0.0 1.0 0.1
    --- @default 1.0
    alpha: number,
}

--- @registerMethod
function CharacterViewport._Ready(self: CharacterViewport)
    self.appearance:SetRigAlpha(self.alpha)
    self.texture = self.viewport:GetTexture()
end

return CharacterViewportC
