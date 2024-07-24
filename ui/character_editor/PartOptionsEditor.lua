local BasicColorPickerButton = require("../../nodes/BasicColorPickerButton")

local PartDatabaseM = require("../../character/appearance/parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

--- @class
--- @extends Control
local PartOptionsEditor = {}
local PartOptionsEditorC = gdclass(PartOptionsEditor)

export type PartOptionsEditor = Control & typeof(PartOptionsEditor) & {
    --- @property
    id: string,

    --- @signal
    optionChanged: SignalWithArgs<(key: string, value: Variant) -> ()>,

    --- @property
    label: Label,

    fields: {[string]: Control},
}

function PartOptionsEditor._Init(self: PartOptionsEditor)
    self.fields = {}
end

--- @registerMethod
function PartOptionsEditor._Ready(self: PartOptionsEditor)
    local partData = PartDatabase:GetPart(self.id)
    if not partData then
        return
    end

    self.label.text = partData.name

    for key, value in partData.optionsSchema do
        if type(key) ~= "string" then
            continue
        end

        if typeof(value) == "Color" then
            local hbox = HBoxContainer.new()
            hbox:AddThemeConstantOverride("separation", 12)

            local label = Label.new()
            label.text = key
            label:AddThemeFontSizeOverride("font_size", 14)
            hbox:AddChild(label)

            local picker = BasicColorPickerButton.new() :: BasicColorPickerButton.BasicColorPickerButton
            picker.customMinimumSize = Vector2.new(96, 32)
            picker.colorChanged:Connect(Callable.new(self, "_OnColorChanged"):Bind(key))
            hbox:AddChild(picker)

            self:AddChild(hbox)

            self.fields[key] = picker
        end
    end
end

--- @registerMethod
function PartOptionsEditor._OnColorChanged(self: PartOptionsEditor, color: Color, key: string)
    self.optionChanged:Emit(key, color)
end

--- @registerMethod
function PartOptionsEditor.Update(self: PartOptionsEditor, config: Dictionary)
    for key, value in config do
        if type(key) ~= "string" then
            continue
        end

        local field = self.fields[key]
        if typeof(field) == "ColorPickerButton" then
            assert(typeof(value) == "Color")
            field.color = value
        else
            error("Unsupported option type")
        end
    end
end

return PartOptionsEditorC
