class_name BasicColorPickerButton
extends ColorPickerButtonSound
## A [ColorPickerButton] with sensible default picker configuration.


func _ready():
	super()
	var picker: ColorPicker = get_picker()

	picker.color_mode = ColorPicker.MODE_HSV
	picker.picker_shape = ColorPicker.SHAPE_HSV_WHEEL
	picker.edit_intensity = false
	picker.sampler_visible = false
	picker.presets_visible = false
