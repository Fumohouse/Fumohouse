local NetworkManagerM = require("../networking/NetworkManager")
local NetworkManager = gdglobal("NetworkManager") :: NetworkManagerM.NetworkManager

local MotionState = {
    CharacterState = {
        NONE = 0,
        IDLE = 1,
        JUMPING = 2,
        FALLING = 4,
        WALKING = 8,
        CLIMBING = 16,
        SITTING = 32,
        SWIMMING = 64,

        DEAD = 32768,
    },
}

MotionState.__index = MotionState

export type WallInfo = {
    point: Vector3,
    normal: Vector3,
    collider: Object,
}

export type Motion = {
    direction: Vector2,
    jump: boolean,
    run: boolean,
    sit: boolean,

    cameraRotation: Vector2,
    cameraMode: number,
}

export type MotionProcessorImpl = {
    __index: MotionProcessorImpl,

    ID: string,

    Initialize: ((self: MotionProcessor, state: MotionState) -> ())?,
    HandleCancel: ((self: MotionProcessor, state: MotionState) -> ())?,
    Process: ((self: MotionProcessor, state: MotionState, delta: number) -> ())?,
    GetVelocity: ((self: MotionProcessor) -> Vector3?)?,
    GetState: ((self: MotionProcessor) -> Variant)?,
    LoadState: ((self: MotionProcessor, state: Variant) -> ())?,

    [any]: any,
}

export type MotionProcessor = typeof(setmetatable({}, {} :: MotionProcessorImpl))

-------------------
-- MotionContext --
-------------------

local MotionContext = {}
MotionContext.__index = MotionContext

function MotionContext.new()
    local self = {}

    -- Input
    self.motion = {
        direction = Vector2.ZERO,
        jump = false,
        run = false,
    } :: Motion

    self.inputDirection = Vector3.ZERO
    self.camBasisFlat = Basis.IDENTITY

    self.isReplay = false

    -- State

    -- List of motion processor IDs which should be cancelled.
    -- Order of processing matters.
    self.cancelledProcessors = {} :: {[string]: boolean}

    -- States which don't really make sense to be applied
    -- (i.e. WALKING when CLIMBING)
    self.cancelledStates = 0

    self.messages = {} :: {[string]: any}

    -- Output
    self.newState = MotionState.CharacterState.NONE
    self.offset = Vector3.ZERO
    self.newBasis = Basis.IDENTITY

    return setmetatable(self, MotionContext)
end

function MotionContext.Reset(self: MotionContext)
    table.clear(self.cancelledProcessors)
    self.cancelledStates = 0
    table.clear(self.messages)
    self.newState = 0
    self.offset = Vector3.ZERO
end

function MotionContext.AddOffset(self: MotionContext, offset: Vector3)
    self.offset += offset
end

function MotionContext.SetState(self: MotionContext, state: number)
    self.newState = bit32.bor(self.newState, state)
end

function MotionContext.CancelProcessor(self: MotionContext, id: string)
    self.cancelledProcessors[id] = true
end

function MotionContext.CancelState(self: MotionContext, state: number)
    self.cancelledStates = bit32.bor(self.cancelledStates, state)
end

export type MotionContext = typeof(MotionContext.new())

-----------------
-- MotionState --
-----------------

function MotionState.new()
    local self = {}

    -- Managed externally --

    self.peer = 0

    -- Objects
    self.node = (nil :: any) :: RigidBody3D -- Kinda janky but avoids unnecessary asserts
    self.rid = RID.new()

    self.mainCollider = (nil :: any) :: CollisionShape3D
    self.mainCollisionShape = (nil :: any) :: CapsuleShape3D

    self.ragdollCollider = (nil :: any) :: CollisionShape3D
    self.ragdollCollisionShape = (nil :: any) :: BoxShape3D

    self.normalCollisionLayer = 0
    self.ragdollCollisionLayer = 0

    -- Options
    self.options = {
        maxGroundAngle = 45,
        margin = 0.001,
    }

    -- State
    self.isGrounded = false
    self.groundRid = RID.new()
    self.groundNormal = Vector3.ZERO

    self.isRagdoll = false

    self.walls = {} :: {WallInfo}
    self.intersections = {
        bodies = {} :: {CollisionObject3D},
        areas = {} :: {Area3D},
    }

    self.velocity = Vector3.ZERO

    self.queueDead = false

    -- Managed locally --

    -- State
    self.state = MotionState.CharacterState.IDLE

    -- Processors
    self.ctx = MotionContext.new()
    self.motionProcessors = {} :: {MotionProcessor}

    local function addProcessor(file: string)
        table.insert(
            self.motionProcessors,
            (require(`processors/{file}.mod`) :: any).new()
        )
    end

    -- Before Grounding due to GROUND_OVERRIDE
    addProcessor("StairsMotion")

    -- Early to prevent errors from objects freed between frames
    -- Coming first also minimizes issues when netcode suddenly changing state, transform, etc. (e.g. grounding state being wrong)
    addProcessor("Intersections")
    addProcessor("Grounding")

    addProcessor("Separator")
    addProcessor("Interpolator")

    addProcessor("Ragdoll")
    addProcessor("LadderMotion")
    addProcessor("SwimMotion")
    addProcessor("HorizontalMotion")
    addProcessor("PhysicalMotion")
    addProcessor("PlatformMotion")
    addProcessor("CollisionMotion")

    addProcessor("Move")

    addProcessor("AreaHandler")
    addProcessor("CharacterAnimator")

    return setmetatable(self, MotionState)
end

function MotionState.ShouldPush(rid: RID): boolean
    local mode = PhysicsServer3D.singleton:BodyGetMode(rid)
    return mode == PhysicsServer3D.BodyMode.RIGID or mode == PhysicsServer3D.BodyMode.RIGID_LINEAR
end

function MotionState.Initialize(self: MotionState, config)
    self.peer = config.peer

    self.node = config.node
    self.rid = config.rid

    self.mainCollider = config.mainCollider
    self.mainCollisionShape = config.mainCollisionShape

    self.ragdollCollider = config.ragdollCollider
    self.ragdollCollisionShape = config.ragdollCollisionShape

    self.normalCollisionLayer = config.normalCollisionLayer
    self.ragdollCollisionLayer = config.ragdollCollisionLayer

    self:SetRagdoll(false)

    for _, processor in self.motionProcessors do
        if processor.Initialize then
            -- TODO: does not type check with :
            processor.Initialize(processor, self)
        end
    end
end

function MotionState.IsRemoteCharacter(self: MotionState)
    return self.peer > 1 and not NetworkManager.isServer
end

function MotionState.GetBottomPosition(self: MotionState)
    if self.isRagdoll then
        local colliderTransform = self.ragdollCollider.globalTransform
        local colliderScale = colliderTransform.basis:GetScale().y

        return colliderTransform.origin - 0.5 * self.ragdollCollisionShape.size.y * colliderScale * colliderTransform.basis.y
    else
        return self.node.globalTransform.origin
    end
end

function MotionState.IsStableGround(self: MotionState, normal: Vector3): boolean
    local ANGLE_MARGIN = 0.01
    return normal:AngleTo(Vector3.UP) <= math.rad(self.options.maxGroundAngle) + ANGLE_MARGIN
end

function MotionState.TestMotion(self: MotionState, params: PhysicsTestMotionParameters3D, result: PhysicsTestMotionResult3D?): boolean
    return PhysicsServer3D.singleton:BodyTestMotion(self.rid, params, result)
end

function MotionState.setBodyMode(self: MotionState, mode: ClassEnumPhysicsServer3D_BodyMode)
    PhysicsServer3D.singleton:BodySetMode(self.rid, mode)
end

function MotionState.SetRagdoll(self: MotionState, ragdoll: boolean)
    self:setBodyMode(if ragdoll then PhysicsServer3D.BodyMode.RIGID else PhysicsServer3D.BodyMode.KINEMATIC)
    self.mainCollider.disabled = ragdoll
    self.ragdollCollider.disabled = not ragdoll

    self.isRagdoll = ragdoll

    self.node.collisionLayer = if ragdoll then self.ragdollCollisionLayer else self.normalCollisionLayer
end

function MotionState.GetMotionProcessor(self: MotionState, id: string): any
    for _, motion in self.motionProcessors do
        if motion.ID == id then
            return motion
        end
    end

    return nil
end

function MotionState.IsState(self: MotionState, state: number): boolean
    return bit32.band(self.state, state) == state
end

function MotionState.IsDead(self: MotionState)
    return self:IsState(MotionState.CharacterState.DEAD)
end

function MotionState.Update(self: MotionState, motion: Motion, delta: number, isReplay: boolean?, persistState: boolean?)
    local origTransform = self.node.globalTransform

    -- Update context
    self.ctx:Reset()

    self.ctx.motion = motion
    self.ctx.inputDirection = Vector3.new(motion.direction.x, 0, motion.direction.y)
    self.ctx.camBasisFlat = Basis.IDENTITY:Rotated(Vector3.UP, motion.cameraRotation.y)

    self.ctx.isReplay = isReplay or false

    if self.queueDead or self:IsState(MotionState.CharacterState.DEAD) then
        self.ctx:SetState(MotionState.CharacterState.DEAD)
        self.queueDead = false
    end

    if persistState then
        self.ctx.newState = self.state
    end

    self.ctx.newBasis = origTransform.basis

    -- Process
    -- Every step of movement from finding the ground to actually moving the character is covered by these processors.
    for _, processor in self.motionProcessors do
        if self.ctx.cancelledProcessors[processor.ID] then
            if processor.HandleCancel then
                -- TODO: does not type check with :
                processor.HandleCancel(processor, self)
            end
        else
            if processor.Process then
                -- TODO: does not type check with :
                processor.Process(processor, self, delta)
            end
        end
    end

    -- Update state
    if self.ctx.newState == MotionState.CharacterState.NONE then
        self.state = MotionState.CharacterState.IDLE
    else
        self.state = bit32.band(
            self.ctx.newState,
            bit32.bnot(self.ctx.cancelledStates)
        )
    end
end

function MotionState.GetState(self: MotionState)
    local state = Dictionary.new()

    for _, processor in self.motionProcessors do
        if processor.GetState then
            local pState = processor.GetState(processor)

            if pState then
                state:Set(processor.ID, pState)
            end
        end
    end

    return state
end

function MotionState.LoadState(self: MotionState, state: Dictionary)
    for id, pState in state do
        assert(type(id) == "string")

        local processor = self:GetMotionProcessor(id)
        if processor.LoadState then
            processor.LoadState(processor, pState)
        end
    end
end

function MotionState.Die(self: MotionState, timeout: number, callback: (() -> ())?)
    -- In case this is called in the middle of a frame
    -- (prevent state from being reset before it can be persisted)
    self.queueDead = true
    self:SetRagdoll(false)

    coroutine.wrap(function()
        wait(timeout)

        if is_instance_valid(self.node) then
            self.node:QueueFree()

            if callback then
                callback()
            end
        end
    end)()
end

export type MotionState = typeof(MotionState.new())
return MotionState
