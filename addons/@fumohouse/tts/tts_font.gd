class_name TTSFont
extends SoundFont
## A [SoundFont] for text-to-speech. Based on
## [url=https://git.seki.pw/Fumohouse/TTS]Fumohouse/TTS (JS).[/url]

const Constants := preload("constants.gd")

## Map of string tokens to sample IDs. If empty, the token is silent.
@export var tokens: Dictionary[String, StringName] = {}
## Catch-all sample names.
@export var symbols: PackedStringArray = []

## List of silent tokens.
@export var silent: PackedStringArray = [
	"?",
	"？",
	"!",
	"！",
	".",
	"。",
	"~",
	"〜",
	",",
	"、",
	"'",
	" ",
	"　",
	"っ",
]
## List of exclamation tokens. Currently not used.
@export var exclaim: PackedStringArray = ["!", "！"]


## Convert a string to a list of triples, where the first element is text in the
## original string comprising the token, the second element is the sample ID
## to be read, and the third element is the duration of the silence after the
## token.
func tokenize(str: String) -> Array[Array]:
	var norm: String = _normalize(str)
	var output: Array[Array] = []

	while not norm.is_empty():
		var max_prefix := ""
		for token in tokens:
			if token.length() > max_prefix.length() and norm.begins_with(token):
				max_prefix = token

		if max_prefix.is_empty():
			var norm_tok := Constants.SMALL_TO_LARGE.get(norm[0], norm[0])
			output.push_back([str[0], _get_sample(norm_tok), _get_spacing(norm_tok)])

			str = str.substr(1)
			norm = norm.substr(1)
		else:
			var norm_tok := Constants.SMALL_TO_LARGE.get(max_prefix, max_prefix)
			output.push_back(
				[str.substr(0, max_prefix.length()), _get_sample(norm_tok), _get_spacing(norm_tok)]
			)

			str = str.substr(max_prefix.length())
			norm = norm.substr(max_prefix.length())

	return output


## Get the spacing (s) to be placed after a given token.
func _get_spacing(token: String) -> float:
	if token == "っ":
		return 0.16

	if token.unicode_at(0) <= 255:
		return 0.058

	return 0.1


## Normalize a string to be tokenized. This function may only replace characters
## in the string; they may not be added or removed, and the final string should
## have the same length as the original.
func _normalize(str: String) -> String:
	var output := ""
	for ch in str:
		ch = ch.to_lower()
		var utf := ch.unicode_at(0)
		if utf >= ord("ァ") and utf <= ord("ヶ"):
			ch = char(utf - ord("ァ") + ord("ぁ"))

		if Constants.REPEAT_CHARS.has(ch) and not output.is_empty():
			var last_char := output[output.length() - 1]

			if Constants.A_REPEAT.has(last_char):
				ch = "あ"
			elif Constants.I_REPEAT.has(last_char):
				ch = "い"
			elif Constants.U_REPEAT.has(last_char):
				ch = "う"
			elif Constants.E_REPEAT.has(last_char):
				ch = "え"
			elif Constants.O_REPEAT.has(last_char):
				ch = "お"
			elif last_char == "ん":
				ch = "ん"

		output += ch

	return output


## Get the sample for the given [param token].
func _get_sample(token: String) -> StringName:
	if silent.has(token):
		return &""

	return tokens.get(token, symbols[randi() % symbols.size()])
