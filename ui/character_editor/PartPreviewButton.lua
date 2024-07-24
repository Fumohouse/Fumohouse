local PreviewButton = require("PreviewButton")
local Appearance = require("../../character/appearance/Appearance")
local AppearanceManager = require("../../character/appearance/AppearanceManager")

--- @class
--- @extends PreviewButton
local PartPreviewButton = {}
local PartPreviewButtonC = gdclass(PartPreviewButton)

export type PartPreviewButton = PreviewButton.PreviewButton & typeof(PartPreviewButton) & {
    --- @property
    id: string,

    --- @property
    appearanceManager: AppearanceManager.AppearanceManager,
}

function PartPreviewButton._Ready(self: PartPreviewButton)
    PreviewButton._Ready(self)

    local appearance = Appearance.new() :: Appearance.Appearance

    local attachedParts = Dictionary.new()
    attachedParts:Set(self.id, nil)
    appearance.attachedParts = attachedParts

    self.appearanceManager.appearance = appearance
    self.appearanceManager:LoadAppearance()
end

return PartPreviewButtonC
