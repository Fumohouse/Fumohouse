local MotionState = require("MotionState.mod")
local CameraController = require("CameraController")
local Utils = require("../utils/Utils.mod")
local Interpolator = require("processors/Interpolator.mod")

local NetworkManagerM = require("../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

local CharacterRequestPacket = require("../networking/packets/runtime/CharacterRequestPacket.mod")
local CharacterStatePacket = require("../networking/packets/runtime/CharacterStatePacket.mod")

--- @class Character
--- @extends RigidBody3D
local Character = {}
local CharacterC = gdclass(Character)

export type NetworkedMotion = {
    userdata: number,
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

    -- 0: singleplayer, 1: local, other: remote
    peer: number,
    motionQueue: {NetworkedMotion},
    queuedStateUpdate: CharacterStatePacket.CharacterStatePacket?,

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
        peer = self.peer,

        node = self,
        rid = self:GetRid(),

        mainCollider = mainCollider,
        mainCollisionShape = assert(mainCollider.shape) :: CapsuleShape3D,

        ragdollCollider = ragdollCollider,
        ragdollCollisionShape = assert(ragdollCollider.shape) :: BoxShape3D,

        normalCollisionLayer = 2,
        ragdollCollisionLayer = 4,
    })

    self:updateCamera()
end

function Character.getMotion(self: Character)
    assert(self.camera)

    local motion = {} :: MotionState.Motion

    if Utils.DoGameInput(self) and not self.state:IsDead() then
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

local nullMotion: MotionState.Motion = {
    direction = Vector2.ZERO,
    jump = false,
    run = false,
    sit = false,

    cameraRotation = Vector2.ZERO,
    cameraMode = 0,
}

local function getMovementFlags(motion: MotionState.Motion)
    local movementFlags = 0

    if motion.jump then
        movementFlags = bit32.bor(movementFlags, CharacterRequestPacket.MovementFlags.JUMP)
    end

    if motion.run then
        movementFlags = bit32.bor(movementFlags, CharacterRequestPacket.MovementFlags.RUN)
    end

    if motion.sit then
        movementFlags = bit32.bor(movementFlags, CharacterRequestPacket.MovementFlags.SIT)
    end

    return movementFlags
end

function Character.sendMovementRequest(self: Character, motion: NetworkedMotion)
    local request = CharacterRequestPacket.client.new(CharacterStatePacket.CharacterStateUpdateType.MOVEMENT)

    request.userdata = motion.userdata
    request.direction = motion.motion.direction

    request.movementFlags = getMovementFlags(motion.motion)
    request.cameraRotation = motion.motion.cameraRotation
    request.cameraMode = motion.motion.cameraMode

    NetworkManager:SendPacket(1, request)
end

function Character.sendMovementUpdate(self: Character, motion: NetworkedMotion)
    local update = CharacterStatePacket.server.new(CharacterStatePacket.CharacterStateUpdateType.MOVEMENT, self.peer)

    update.transform = self.globalTransform

    update.state = self.state.state
    update.bodyMode = PhysicsServer3D.singleton:BodyGetMode(self:GetRid())
    update.processorState = self.state:GetState()
    update.isRagdoll = self.state.isRagdoll
    update.movementAck = motion.userdata

    update.velocity = self.linearVelocity
    update.angularVelocity = self.angularVelocity

    NetworkManager:SendPacket(self.peer, update)

    update.movementAck = 0

    for peer, _ in NetworkManager.peerData do
        if peer == self.peer then
            continue
        end

        NetworkManager:SendPacket(peer, update)
    end
end

function Character.ackQueue(self: Character, ack: number)
    local i = 1

    while i <= #self.motionQueue and self.motionQueue[i].userdata <= ack do
        i += 1
    end

    local newQueue = {}
    table.move(self.motionQueue, i, #self.motionQueue, 1, newQueue)

    self.motionQueue = newQueue
end

--- @registerMethod
function Character._PhysicsProcess(self: Character, delta: number)
    if self.queuedStateUpdate then
        self.state.state = self.queuedStateUpdate.state
        self.state:LoadState(self.queuedStateUpdate.processorState)
        self.state:SetRagdoll(self.queuedStateUpdate.isRagdoll)
        self.state:SetBodyMode(self.queuedStateUpdate.bodyMode)

        self.linearVelocity = self.queuedStateUpdate.velocity
        self.angularVelocity = self.queuedStateUpdate.angularVelocity

        local interpolator = self.state:GetMotionProcessor(Interpolator.ID)

        if self.peer == 1 then
            local initialTransform = self.globalTransform
            self.globalTransform = self.queuedStateUpdate.transform

            self:ackQueue(self.queuedStateUpdate.movementAck)

            for _, motion in self.motionQueue do
                self.state:Update(motion.motion, delta, true)
            end

            local targetTransform = self.globalTransform
            self.globalTransform = initialTransform

            interpolator:SetTarget(targetTransform)
        else
            interpolator:SetTarget(self.queuedStateUpdate.transform)
        end

        self.queuedStateUpdate = nil
    end

    if not NetworkManager.isActive then
        if not self.camera then
            return
        end

        self.state:Update(self:getMotion(), delta)
    elseif self.peer == 1 then
        local frames = Engine.singleton:GetPhysicsFrames()

        local motion = self:getMotion()
        local netMotion = {
            userdata = frames,
            motion = motion,
        }

        self.motionQueue[#self.motionQueue + 1] = netMotion

        self.state:Update(motion, delta)
        self:sendMovementRequest(netMotion)
    elseif NetworkManager.isServer then
        local MAX_QUEUE_SIZE = 4

        -- Loop to avoid overwhelming client (& memory)
        repeat
            local motion = table.remove(self.motionQueue, 1)

            if motion then
                local actualMotion = motion.motion

                if self.state:IsDead() then
                    -- Client sends nothing, but reset anyway in case hacking
                    actualMotion.direction = Vector2.ZERO

                    actualMotion.jump = false
                    actualMotion.run = false
                    actualMotion.sit = false
                end

                self.state:Update(actualMotion, delta)

                if Engine.singleton:GetPhysicsFrames() % 3 == 0 then
                    self:sendMovementUpdate(motion)
                end
            end
        until #self.motionQueue <= MAX_QUEUE_SIZE
    else
        self.state:Update(nullMotion, delta, false, true)
    end
end

function Character.ProcessMovementRequest(self: Character, packet: CharacterRequestPacket.CharacterRequestPacket)
    local flags = packet.movementFlags

    self.motionQueue[#self.motionQueue + 1] = {
        userdata = packet.userdata,
        motion = {
            direction = packet.direction,
            jump = bit32.band(flags, CharacterRequestPacket.MovementFlags.JUMP) ~= 0,
            run = bit32.band(flags, CharacterRequestPacket.MovementFlags.RUN) ~= 0,
            sit = bit32.band(flags, CharacterRequestPacket.MovementFlags.SIT) ~= 0,

            cameraRotation = packet.cameraRotation,
            cameraMode = packet.cameraMode,
        },
    }
end

function Character.ProcessMovementUpdate(self: Character, packet: CharacterStatePacket.CharacterStatePacket)
    if self.peer == 1 and (#self.motionQueue == 0 or packet.movementAck < self.motionQueue[1].userdata) then
        return
    end

    self.queuedStateUpdate = packet
end

return CharacterC
