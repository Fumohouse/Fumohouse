local PreviewButton = require("PreviewButton")
local FacePartStyle = require("../../character/appearance/face/FacePartStyle")
local EyeStyle = require("../../character/appearance/face/EyeStyle")

--- @class
--- @extends PreviewButton
local FacePreviewButton = {}
local FacePreviewButtonC = gdclass(FacePreviewButton)

--- @classType FacePreviewButton
export type FacePreviewButton = PreviewButton.PreviewButton & typeof(FacePreviewButton) & {
    --- @property
    style: Resource,

    --- @property
    layer1: TextureRect,
    --- @property
    layer2: TextureRect,
    --- @property
    layer3: TextureRect,

    id: string,
}

function FacePreviewButton._Ready(self: FacePreviewButton)
    PreviewButton._Ready(self)

    if self.style:IsA(FacePartStyle) then
        local fps = self.style :: FacePartStyle.FacePartStyle
        self.layer1.texture = fps.texture

        self.id = fps.name
    elseif self.style:IsA(EyeStyle) then
        local es = self.style :: EyeStyle.EyeStyle
        self.layer1.texture = es.eyes
        self.layer2.texture = es.overlay
        self.layer3.texture = es.shine

        self.id = es.name
    end
end

return FacePreviewButtonC
