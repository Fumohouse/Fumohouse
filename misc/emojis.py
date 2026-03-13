from pathlib import Path
import json
import polib


def unsmart(string):
	return string.replace("‘", "'").replace("’", "'").replace("“", '"').replace("”", '"')


path = Path(__file__).parent

lang = input("Language (e.g., en): ")

emojibase = path / "emojibase"
raw_path = emojibase / "packages" / "data" / lang / "data.raw.json"
shortcodes_path = emojibase / "po" / lang / "shortcodes.po"

# Get advanced Emoji data
raw_data = None
with open(raw_path, "rb") as f:
	raw_data = json.load(f)

emoji_data = {}
for entry in raw_data:
	emoji_data[entry["emoji"]] = entry

# Get shortcodes for each emoji
shortcodes = {}

for entry in polib.pofile(shortcodes_path):
	emoji = entry.msgctxt.split(" ")[1]
	shortcode = entry.msgstr
	if len(shortcode) == 0:
		continue

	if emoji in shortcodes:
		shortcodes[emoji].append(shortcode)
	else:
		shortcodes[emoji] = [shortcode]

# Generate final database
emojis = []

for emoji in shortcodes:
	data = emoji_data[emoji]
	shortcode = shortcodes[emoji]

	row = f"{emoji}\t{unsmart(data["label"])}\t{",".join(shortcode)}"

	if "tags" in data:
		tags = [unsmart(t) for t in data["tags"]]
		row += "\t" + ",".join(tags)

	emojis.append(row)

print("\n".join(emojis))
