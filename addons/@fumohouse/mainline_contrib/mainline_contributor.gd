class_name MainlineContributor
extends Resource
## Resource representing mainline contributors.

## The contributor's name.
@export var name := ""
## Category of contributor.
@export var category := &""
## If non-negative, determines the order contributors are displayed. Lower
## numbers have higher priority.
@export var weight := -1
## A brief phrase describing the contributor's role, or empty for none.
@export var role := ""
## Description of the contributor's contributions.
@export_multiline var description := ""
