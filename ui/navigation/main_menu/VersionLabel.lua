local Utils = require("../../../utils/Utils.mod")

local VersionLabelImpl = {}
local VersionLabel = gdclass(nil, Control)
    :RegisterImpl(VersionLabelImpl)

export type VersionLabel = Control & typeof(VersionLabelImpl)

function VersionLabelImpl._Ready(self: VersionLabel)
    local stageBg = self:GetNode("Stage/Background") :: ColorRect
    stageBg.color = Utils.stageColor

    local stageText = self:GetNode("Stage/Text") :: Label
    stageText.text = Utils.stageAbbrev

    local versionText = self:GetNode("Version") :: Label
    versionText.text = Utils.version
end

VersionLabel:RegisterMethod("_Ready")

return VersionLabel
