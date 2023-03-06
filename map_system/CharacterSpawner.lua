local CameraController = require("../character/CameraController")

local CharacterSpawnerImpl = {}
local CharacterSpawner = gdclass(nil, Node3D)
    :RegisterImpl(CharacterSpawnerImpl)

export type CharacterSpawner = Node3D & typeof(CharacterSpawnerImpl)

function CharacterSpawnerImpl.SpawnCharacter(self: CharacterSpawner, defaultScene: PackedScene, camera: CameraController.CameraController): Node3D?
    return nil
end

CharacterSpawner:RegisterMethod("SpawnCharacter")
    :Args(
        { name = "defaultScene", type = Enum.VariantType.OBJECT, className = "PackedScene" },
        { name = "camera", type = Enum.VariantType.OBJECT, className = "Camera3D" }
    )
    :ReturnVal({ type = Enum.VariantType.OBJECT, className = "Node3D" })

return CharacterSpawner
