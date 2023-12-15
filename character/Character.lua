local MotionState = require("MotionState.mod")
local CameraController = require("CameraController")
local Utils = require("../utils/Utils.mod")

local NetworkManagerM = require("../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

--- @class Character
--- @extends RigidBody3D
local Character = {}
local CharacterC = gdclass(Character)

export type NetworkedMotion = {
    frame: number,
    motion: MotionState.Motion,
}

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

    -- 1: local, other: remote
    peer: number,
    motionQueue: {NetworkedMotion},

    lastCameraRotation: Vector2,
    lastCameraMode: number,
}

function Character._Init(self: Character)
    self.state = MotionState.new()

    self.peer = 0
    self.motionQueue = {}

    self.lastCameraRotation = Vector2.new()
    self.lastCameraMode = 0
end

function Character.updateCamera(self: Character)
    if not self:IsInsideTree() then
        return
    end

    if self.camera then
        self.camera.focusNode = self
        self.cameraUpdated:Emit(self.camera)
    end
end

--- @registerMethod
function Character.setCamera(self: Character, camera: CameraController.CameraController?)
    if self.cameraInternal then
        self.cameraInternal.focusNode = nil
    end

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

function Character.getMotion(self: Character)
    assert(self.camera)

    local motion = {} :: MotionState.Motion

    if Utils.DoGameInput(self) then
        motion.direction = Input.singleton:GetVector("move_left", "move_right", "move_forward", "move_backward")
        motion.jump = Input.singleton:IsActionPressed("move_jump")
        motion.run = Input.singleton:IsActionPressed("move_run")
        motion.sit = Input.singleton:IsActionJustPressed("move_sit")
    else
        motion.direction = Vector2.ZERO
        motion.jump = false
        motion.run = false
        motion.sit = false
    end

    motion.cameraRotation = self.camera.cameraRotation
    motion.cameraMode = self.camera.cameraMode

    return motion
end

--- @registerMethod
function Character._PhysicsProcess(self: Character, delta: number)
    if not NetworkManager.isActive then
        -- Singleplayer handling
        if not self.camera then
            return
        end

        self.state:Update(self:getMotion(), delta)
    elseif self.peer == 1 then
        -- Local handling
        local motion = self:getMotion()
        self.state:Update(self:getMotion(), delta)

        self.motionQueue[#self.motionQueue + 1] = {
            frame = Engine.singleton:GetPhysicsFrames(),
            motion = motion,
        }
    elseif NetworkManager.isServer then
        -- Remote handling (server)
        local motion = table.remove(self.motionQueue, 1)
        if not motion then
            self.state:Update({
                direction = Vector2.ZERO,
                jump = false,
                run = false,
                sit = false,

                cameraRotation = self.lastCameraRotation,
                cameraMode = self.lastCameraMode,
            }, delta)

            return
        end

        self.state:Update(motion.motion, delta)
    end
end

return CharacterC
