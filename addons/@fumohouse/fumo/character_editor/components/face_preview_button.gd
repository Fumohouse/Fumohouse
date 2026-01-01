extends "preview_button.gd"

@export var style: Resource

var id: StringName:
	get:
		return style.get(&"id")

@onready var _layer_1: TextureRect = %Layer1
@onready var _layer_2: TextureRect = %Layer2
@onready var _layer_3: TextureRect = %Layer3


func _ready():
	super()

	tooltip_text = id

	if style is FumoFacePartStyle:
		var fps := style as FumoFacePartStyle
		_layer_1.texture = fps.texture
	elif style is FumoEyeStyle:
		var es := style as FumoEyeStyle
		_layer_1.texture = es.eyes
		_layer_2.texture = es.overlay
		_layer_3.texture = es.shine
