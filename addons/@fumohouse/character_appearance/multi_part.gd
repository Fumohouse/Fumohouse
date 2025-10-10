class_name MultiPart
extends PartData
## An attachable part consisting of multiple [SinglePart]s.

## The list of parts to attach. They should have the scope
## [constant PartData.Scope.NONE].
@export var parts: Array[SinglePart] = []
