local Utils = require("../../../utils/Utils.mod")

--- @class
--- @extends Control
local VersionLabel = {}
local VersionLabelC = gdclass(VersionLabel)

--- @classType VersionLabel
export type VersionLabel = Control & typeof(VersionLabel)

--- @registerMethod
function VersionLabel._Ready(self: VersionLabel)
    local stageBg = self:GetNode("Stage/Background") :: ColorRect
    stageBg.color = Utils.stageColor

    local stageText = self:GetNode("Stage/Text") :: Label
    stageText.text = Utils.stageAbbrev

    local versionText = self:GetNode("Version") :: Label
    versionText.text = Utils.version
end

return VersionLabelC
