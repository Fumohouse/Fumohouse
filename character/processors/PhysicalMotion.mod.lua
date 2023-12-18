--[[
    Responsible for all motion which should be affected by gravity
    (falling, jumping, etc.)
]]

local MotionState = require("../MotionState.mod")
local Utils = require("../../utils/Utils.mod")

local PhysicalMotion = {
    ID = "physical",
    DRAG = "drag",
    JUMP = "jump",
}

PhysicalMotion.__index = PhysicalMotion

function PhysicalMotion.new()
    local self = {}

    self.velocity = Vector3.ZERO
    self.airborneTime = 0
    self.cancelJump = false -- until grounded

    self.options = {
        gravity = 50,
        jumpHeight = 4.5,
        jumpForgiveness = 0.2, -- seconds
        jumpBounceFactor = 0.7,

        -- FALLING state options
        fallingTime = 0.3,
        fallingAltitude = 2,
    }

    return setmetatable(self, PhysicalMotion)
end

function PhysicalMotion.Initialize(self: PhysicalMotion, state: MotionState.MotionState)
    if state.node:IsA(RigidBody3D) then
        (state.node :: RigidBody3D).gravityScale = self.options.gravity / (ProjectSettings.singleton:GetSetting("physics/3d/default_gravity") :: number)
    end
end

function PhysicalMotion.getJumpVelocity(self: PhysicalMotion, height: number)
    -- Kinematics
    return math.sqrt(2 * self.options.gravity * height)
end

function PhysicalMotion.HandleCancel(self: PhysicalMotion, state: MotionState.MotionState)
    self.velocity = Vector3.ZERO
    self.airborneTime = 0
end

function PhysicalMotion.Process(self: PhysicalMotion, state: MotionState.MotionState, delta: number)
    local ctx = state.ctx
    local wasJumping = state:IsState(MotionState.CharacterState.JUMPING)

    -- > 0: force jump with given height, 0: block jump
    local jumpMsg = ctx.messages[PhysicalMotion.JUMP] :: number?

    if state.isGrounded and not wasJumping or state.isRagdoll then
        self.velocity = Vector3.ZERO
        self.cancelJump = jumpMsg == 0
    else
        self.velocity += Vector3.DOWN * self.options.gravity * delta
    end

    local drag = ctx.messages[PhysicalMotion.DRAG] :: number?
    if drag then
        self.velocity = Utils.ApplyDrag(self.velocity, drag, delta)
    end

    if jumpMsg or
            (ctx.motion.jump and
            self.airborneTime < self.options.jumpForgiveness and
            not self.cancelJump and
            not wasJumping) then
        self.velocity = Vector3.UP * self:getJumpVelocity(jumpMsg or self.options.jumpHeight)
        self.cancelJump = true
        ctx:SetState(MotionState.CharacterState.JUMPING)

        state:SetRagdoll(false)
    elseif wasJumping and self.velocity.y >= 0 and not state.isRagdoll then
        -- Persist jump state until falling
        ctx:SetState(MotionState.CharacterState.JUMPING)

        -- Hit detection
        local roofParams = PhysicsTestMotionParameters3D.new()
        roofParams.from = state.GetTransform()
        roofParams.motion = Vector3.UP * self.velocity.y * delta
        roofParams.margin = state.options.margin

        local roofResult = PhysicsTestMotionResult3D.new()

        if state:TestMotion(roofParams, roofResult) then
            self.velocity = self.velocity:Bounce(roofResult:GetCollisionNormal()) * self.options.jumpBounceFactor
        end
    end

    ctx:AddOffset(self.velocity * delta)

    -- Decide whether character is falling
    if state.isGrounded then
        self.airborneTime = 0
    else
        self.airborneTime += delta

        if self.airborneTime > self.options.fallingTime and self.velocity.y < 0 then
            if state:IsState(MotionState.CharacterState.FALLING) then
                ctx:SetState(MotionState.CharacterState.FALLING)
            else
                local fallRayParams = PhysicsRayQueryParameters3D.new()
                fallRayParams.from = state.GetTransform().origin
                fallRayParams.to = fallRayParams.from + Vector3.DOWN * self.options.fallingAltitude

                local fallRayResult = state.GetWorld3D().directSpaceState:IntersectRay(fallRayParams)
                if fallRayResult:IsEmpty() then
                    ctx:SetState(MotionState.CharacterState.FALLING)
                end
            end
        end
    end
end

function PhysicalMotion.GetVelocity(self: PhysicalMotion): Vector3?
    return self.velocity
end

function PhysicalMotion.GetState(self: PhysicalMotion)
    local state = Dictionary.new()

    state:Set("v", self.velocity)
    state:Set("at", self.airborneTime)
    state:Set("cj", self.cancelJump)

    return state
end

function PhysicalMotion.LoadState(self: PhysicalMotion, state: Variant)
    assert(typeof(state) == "Dictionary")

    if state:Has("v") then
        local val = state:Get("v")
        assert(typeof(val) == "Vector3")
        self.velocity = val
    end

    if state:Has("at") then
        local val = state:Get("at")
        assert(typeof(val) == "number")
        self.airborneTime = val
    end

    if state:Has("cj") then
        local val = state:Get("cj")
        assert(typeof(val) == "boolean")
        self.cancelJump = val
    end
end

export type PhysicalMotion = typeof(PhysicalMotion.new())
return PhysicalMotion
