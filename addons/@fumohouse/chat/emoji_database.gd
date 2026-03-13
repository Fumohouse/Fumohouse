class_name EmojiDatabase
extends Node
## Utility class for finding emojis based on tags or short codes.

const LOG_SCOPE := "EmojiDatabase"

var emojis: Array[Emoji] = []


static func get_singleton() -> EmojiDatabase:
	return Modules.get_singleton(&"EmojiDatabase") as EmojiDatabase


func _ready():
	emojis = _load_file("res://addons/@fumohouse/chat/resources/emojibase/en.txt")


## Get an emoji by its exact short code.
func get_by_short_code(short_code: String) -> String:
	for emoji in emojis:
		if emoji.short_codes.has(short_code):
			return emoji.emoji
	return ""


func _load_file(path: String) -> Array[Emoji]:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		Log.error("Failed to read file: %s" % path, LOG_SCOPE)
		return []

	var out: Array[Emoji] = []

	while not file.eof_reached():
		var line_split: PackedStringArray = file.get_line().split("\t")
		if line_split.size() < 3:
			continue

		var emoji := Emoji.new()
		emoji.emoji = line_split[0]
		emoji.label = line_split[1]
		emoji.short_codes = line_split[2].split(",")

		if line_split.size() >= 4:
			emoji.tags = line_split[3].split(",")

		out.push_back(emoji)

	Log.debug("Loaded %d emojis from %s" % [out.size(), path], LOG_SCOPE)
	return out


class Emoji:
	extends RefCounted
	var emoji: String
	var label: String
	var short_codes: PackedStringArray
	var tags: PackedStringArray
