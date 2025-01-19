extends Control

@onready var _stage_bg: ColorRect = $Stage/Background
@onready var _stage_text: Label = $Stage/Text
@onready var _version_text: Label = $Version


func _ready():
	_stage_bg.color = Color.from_string(DistConfig.STAGE_COLOR, Color.WHITE)
	_stage_text.text = DistConfig.STAGE_ABBREV
	_version_text.text = DistConfig.VERSION
