class_name FumoEyeStyle
extends Resource
## Resource describing the main eye style.

## Unique ID of the style.
@export var id := &""

## Main eye texture.
@export var eyes: Texture2D
## Eye shine texture.
@export var shine: Texture2D
## Generic eye overlay (e.g., eyelashes).
@export var overlay: Texture2D

## If [code]true[/code], [member eyes] can be recolored.
@export var supports_recoloring := true
