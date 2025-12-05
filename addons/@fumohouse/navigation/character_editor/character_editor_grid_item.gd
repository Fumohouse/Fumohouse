class_name CharacterEditorGridItem
extends Button


func _ready():
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _init(appearance: Appearance):
	self.text = appearance.display_name
