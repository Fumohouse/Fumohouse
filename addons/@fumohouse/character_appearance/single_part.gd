class_name SinglePart
extends PartData
## An attachable part consisting of one component.

## Path to the scene representing this part.
@export_file("*.tscn", "*.glb") var scene_path := ""

## The transform of this part relative to the bone attachment.
@export var transform := Transform3D.IDENTITY

## The name of the bone to attach this part to.
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Torso,Head,LArm,RArm,LLeg,RLeg") var bone := "Torso"
