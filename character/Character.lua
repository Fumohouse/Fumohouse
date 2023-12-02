local MotionState = require("MotionState.mod")
local CameraController = require("CameraController")

--- @class Character
--- @extends RigidBody3D
local Character = {}
local CharacterC = gdclass(Character)

--- @classType Character
export type Character = RigidBody3D & typeof(Character) & {
    --- @property
    --- @set setCamera
    --- @get getCamera
    camera: CameraController.CameraController?,

    --- @signal
    cameraUpdated: SignalWithArgs<(camera: Camera3D) -> ()>,

    state: MotionState.MotionState,
    cameraInternal: CameraController.CameraController?,
}

function Character._Init(self: Character)
    self.state = MotionState.new()
end

function Character.updateCamera(self: Character)
    if not self:IsInsideTree() then
        return
    end

    if self.state.camera then
        self.state.camera.focusNode = nil
    end

    if not self.camera then
        self.state.camera = nil
    else
        self.camera.focusNode = self
        self.state.camera = self.camera

        self.cameraUpdated:Emit(self.camera)
    end
end

--- @registerMethod
function Character.setCamera(self: Character, camera: CameraController.CameraController?)
    self.cameraInternal = camera
    self:updateCamera()
end

--- @registerMethod
function Character.getCamera(self: Character): CameraController.CameraController?
    return self.cameraInternal
end

--- @registerMethod
function Character._Ready(self: Character)
    local mainCollider = self:GetNode("MainCollider") :: CollisionShape3D
    local ragdollCollider = self:GetNode("RagdollCollider") :: CollisionShape3D

    self.state:Initialize({
        node = self,
        rid = self:GetRid(),

        mainCollider = mainCollider,
        mainCollisionShape = assert(mainCollider.shape) :: CapsuleShape3D,

        ragdollCollider = ragdollCollider,
        ragdollCollisionShape = assert(ragdollCollider.shape) :: BoxShape3D,

        GetTransform = function() return self.globalTransform end,
        SetTransform = function(transform) self.globalTransform = transform end,
        GetWorld3D = function() return self:GetWorld3D() end,
    })

    self:updateCamera()
end

--- @registerMethod
function Character._PhysicsProcess(self: Character, delta: number)
    if self.state.camera then
        self.state:Update(delta)
    end
end

return CharacterC
