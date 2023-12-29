--- @class BasicColorPickerButton
--- @extends ColorPickerButton
local BasicColorPickerButton = {}
local BasicColorPickerButtonC = gdclass(BasicColorPickerButton)

--- @classType BasicColorPickerButton
export type BasicColorPickerButton = ColorPickerButton & typeof(BasicColorPickerButton)

--- @registerMethod
function BasicColorPickerButton._Ready(self: BasicColorPickerButton)
    local picker = self:GetPicker()

    picker.colorMode = ColorPicker.ColorModeType.HSV
    picker.pickerShape = ColorPicker.PickerShapeType.HSV_WHEEL
    picker.samplerVisible = false
    picker.presetsVisible = false
end

return BasicColorPickerButtonC
