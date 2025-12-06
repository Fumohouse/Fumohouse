class_name CharacterEditorGridItem
extends Button

var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()


func _ready():
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _stage_appearance(appearance: Appearance):
	fumo_appearances.staging = appearance


func _init(appearance: Appearance):
	self.text = appearance.display_name
	self.pressed.connect(_stage_appearance.bind(appearance))
