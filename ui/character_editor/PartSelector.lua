local RadioButtonContainer = require("../../nodes/RadioButtonContainer")
local PartPreviewButton = require("PartPreviewButton")

local PartDatabaseM = require("../../character/appearance/parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

--- @class
--- @extends RadioButtonContainer
local PartSelector = {}
local PartSelectorC = gdclass(PartSelector)

--- @classType PartSelector
export type PartSelector = RadioButtonContainer.RadioButtonContainer & typeof(PartSelector) & {
    -- Update with PartData.Scope
    --- @property
    --- @enum None Accessory Outfit Hair Shoes Hat Ears Tail
    scope: integer,

    buttons: {[string]: PartPreviewButton.PartPreviewButton},
}

local buttonScene: PackedScene = assert(load("res://ui/character_editor/part_preview_button.tscn"))

function PartSelector._Init(self: PartSelector)
    self.buttons = {}
end

--- @registerMethod
function PartSelector._Ready(self: PartSelector)
    for id, data in PartDatabase.parts do
        if data.scope ~= self.scope then
            continue
        end

        local button = buttonScene:Instantiate() :: PartPreviewButton.PartPreviewButton
        button.id = id

        self:AddChild(button)
        self.buttons[id] = button
    end
end

function PartSelector.GetSelectionIds(self: PartSelector)
    local selection

    if self.multiSelection then
        selection = {}

        for _, button: PartPreviewButton.PartPreviewButton in self.selectedButtons do
            table.insert(selection, button.id)
        end
    elseif self.selectedButton then
        selection = {(self.selectedButton :: PartPreviewButton.PartPreviewButton).id}
    end

    return selection
end

function PartSelector.SetSelectionIds(self: PartSelector, ids: {string})
    if self.multiSelection then
        local selection = Array.new()

        for _, id in ids do
            selection:PushBack(self.buttons[id])
        end

        self.selectedButtons = selection
    else
        self.selectedButton = if #ids > 0 then self.buttons[ids[1]] else nil
    end
end

return PartSelectorC
