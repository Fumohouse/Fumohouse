class_name Voicebox3D
extends SoundFontPlayer3D
## A node that can play strings using a [TTSFont] in 3D.

const LOG_SCOPE := "Voicebox3D"

## The pitch/tempo for the voice.
@export_range(0.7, 3.0, 0.05) var pitch := 1.25


func _ready():
	if font and font is not TTSFont:
		Log.error("Voicebox3D font must be a TTSFont.", LOG_SCOPE)


## Read the given [param string] using [member font]. Calls [param on_token]
## when each token is read. Asynchronous function returns when the full message
## is read.
func read(string: String, on_token := Callable()):
	var tts_font := font as TTSFont
	var tokens: Array[Array] = tts_font.tokenize(string)

	var msg_pitch := pitch
	var is_exclaim: bool = (
		not tokens.is_empty() and tts_font.exclaim.has(tokens[tokens.size() - 1][0])
	)
	if is_exclaim:
		msg_pitch += 0.04

	for token: Array in tokens:
		var orig_tok: String = token[0]
		var sample: StringName = token[1]
		var spacing: float = token[2]

		if on_token.is_valid():
			on_token.call(orig_tok)

		if not sample.is_empty():
			var tok_pitch := msg_pitch + randf_range(-0.05, 0.05)
			play(sample, func(player: AudioStreamPlayer3D): player.pitch_scale = tok_pitch)

		await get_tree().create_timer(spacing).timeout


func _get_player() -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = super._get_player()
	player.bus = &"TTS"
	return player
