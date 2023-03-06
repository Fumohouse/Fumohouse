local MotionState = require("MotionState.mod")
local CameraController = require("CameraController")

local CharacterImpl = {}
local Character = gdclass("Character", RigidBody3D)
    :RegisterImpl(CharacterImpl)

type CharacterT = {
    cameraPath: string,
    cameraUpdated: Signal,

    cameraPathInternal: string,
    state: MotionState.MotionState,
}

export type Character = RigidBody3D & CharacterT & typeof(CharacterImpl)

Character:RegisterProperty("cameraPath", Enum.VariantType.NODE_PATH)
    :NodePath("Camera3D")
    :SetGet("setCameraPath", "getCameraPath")

Character:RegisterSignal("cameraUpdated")
    :Args({ name = "camera", type = Enum.VariantType.OBJECT, className = "Camera3D" })

function CharacterImpl._Init(obj: RigidBody3D, tbl: CharacterT)
    tbl.state = MotionState.new()

    tbl.cameraPathInternal = ""
end

function CharacterImpl.updateCamera(self: Character)
    if not self:IsInsideTree() then
        return
    end

    if self.state.camera then
        self.state.camera.focusNode = nil
    end

    if self.cameraPathInternal == "" then
        self.state.camera = nil
    else
        local camera = self:GetNode(self.cameraPathInternal) :: CameraController.CameraController
        camera.focusNode = self
        self.state.camera = camera

        self.cameraUpdated:Emit(camera)
    end
end

function CharacterImpl.setCameraPath(self: Character, path: string)
    self.cameraPathInternal = path
    self:updateCamera()
end

Character:RegisterMethod("setCameraPath")
    :Args({ name = "path", type = Enum.VariantType.NODE_PATH })

function CharacterImpl.getCameraPath(self: Character)
    return self.cameraPathInternal
end

Character:RegisterMethod("getCameraPath")
    :ReturnVal({ type = Enum.VariantType.NODE_PATH })

function CharacterImpl._Ready(self: Character)
    local mainCollider = self:GetNode("Capsule") :: CollisionShape3D

    self.state:Initialize({
        node = self,
        rid = self:GetRid(),

        mainCollider = mainCollider,
        mainCollisionShape = assert(mainCollider.shape) :: CapsuleShape3D,

        GetTransform = function() return self.globalTransform end,
        SetTransform = function(transform) self.globalTransform = transform end,
        GetWorld3D = function() return self:GetWorld3D() end,
        MoveAndCollide = function(motion, margin) return self:MoveAndCollide(motion, false, margin) end,
    })

    self:updateCamera()
end

Character:RegisterMethod("_Ready")

function CharacterImpl._PhysicsProcess(self: Character, delta: number)
    if self.state.camera then
        self.state:Update(delta)
    end
end

Character:RegisterMethodAST("_PhysicsProcess")

return Character
