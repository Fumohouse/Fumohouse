extends PanelContainer

var voicebox: Voicebox3D

@onready var _text: RichTextLabel = %Text
@onready var _font: TTSFont = voicebox.font as TTSFont


func on_token(token: String):
	_text.text += token
	if _font.exclaim.has(token):
		var tween := get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUAD).tween_property(_text, "modulate", Color.RED, 0.1)
		tween.set_trans(Tween.TRANS_LINEAR).tween_property(_text, "modulate", Color.WHITE, 0.5)
