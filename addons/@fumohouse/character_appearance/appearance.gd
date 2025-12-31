class_name Appearance
extends Resource
## A character appearance.

## Display name of the appearance preset.
@export var display_name := ""

## Global appearance configuration, such as facial appearance.
@export var config: Dictionary[StringName, Variant] = {
	&"eyebrows": null,
	&"eyes": null,
	&"mouth": null,
	&"eyes_color": Color.WHITE,
	&"scale": 1.0,
}

## Attached part configuration. The value should be [code]null[/code] or a
## [Dictionary].
@export var attached_parts: Dictionary[StringName, Variant] = {}
