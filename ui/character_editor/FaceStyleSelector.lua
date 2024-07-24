local RadioButtonContainer = require("../../nodes/RadioButtonContainer")
local FaceDatabase = require("../../character/appearance/face/FaceDatabase")
local FacePreviewButton = require("FacePreviewButton")

--- @class
--- @extends RadioButtonContainer
local FaceStyleSelector = {}
local FaceStyleSelectorC = gdclass(FaceStyleSelector)

export type FaceStyleSelector = RadioButtonContainer.RadioButtonContainer & typeof(FaceStyleSelector) & {
    --- @property
    --- @enum Eye Eyebrow Mouth
    partType: integer,

    buttons: {[string]: FacePreviewButton.FacePreviewButton},
}

local faceDatabase: FaceDatabase.FaceDatabase = assert(load("res://resources/face_database.tres"))
local buttonScene: PackedScene = assert(load("face_preview_button.tscn"))

function FaceStyleSelector._Init(self: FaceStyleSelector)
    self.buttons = {}
end

--- @registerMethod
function FaceStyleSelector._Ready(self: FaceStyleSelector)
    local list

    if self.partType == 0 then
        list = faceDatabase.eyeStyles
    elseif self.partType == 1 then
        list = faceDatabase.eyebrowStyles
    elseif self.partType == 2 then
        list = faceDatabase.mouthStyles
    end

    for _, res: Resource in list do
        local button = buttonScene:Instantiate() :: FacePreviewButton.FacePreviewButton
        button.style = res

        self:AddChild(button)

        self.buttons[button.id] = button
    end
end

function FaceStyleSelector.GetSelectionId(self: FaceStyleSelector)
    return if self.selectedButton then (self.selectedButton :: FacePreviewButton.FacePreviewButton).id else ""
end

function FaceStyleSelector.SetSelectionId(self: FaceStyleSelector, id: string)
    self.selectedButton = self.buttons[id]
end

return FaceStyleSelectorC
