--[[
    Responsible for all motion which should be affected by gravity
    (falling, jumping, etc.)
]]

local MotionState = require("../MotionState.mod")

local PhysicalMotion = setmetatable({
    ID = "physical",
}, MotionState.MotionProcessor)

PhysicalMotion.__index = PhysicalMotion

function PhysicalMotion.new()
    local self = {}

    self.velocity = Vector3.ZERO
    self.airborneTime = 0
    self.options = {
        gravity = 50,
        jumpHeight = 4.5,
        jumpForgiveness = 0.2, -- seconds

        -- FALLING state options
        fallingTime = 0.3,
        fallingAltitude = 2,
    }

    return setmetatable(self, PhysicalMotion)
end

function PhysicalMotion.Initialize(self: PhysicalMotion, state: MotionState.MotionState)
    if state.node:IsA(RigidBody3D) then
        (state.node :: RigidBody3D).gravityScale = self.options.gravity / (ProjectSettings.GetSingleton():GetSetting("physics/3d/default_gravity") :: number)
    end
end

function PhysicalMotion.getJumpVelocity(self: PhysicalMotion)
    -- Kinematics
    return math.sqrt(2 * self.options.gravity * self.options.jumpHeight)
end

function PhysicalMotion.HandleCancel(self: PhysicalMotion, state: MotionState.MotionState)
    self.velocity = Vector3.ZERO
    self.airborneTime = 0
end

function PhysicalMotion.Process(self: PhysicalMotion, state: MotionState.MotionState, delta: number)
    local ctx = state.ctx
    local wasJumping = state:IsState(MotionState.CharacterState.JUMPING)

    if state.isGrounded and not wasJumping or state.isRagdoll then
        self.velocity = Vector3.ZERO
    else
        self.velocity += Vector3.DOWN * self.options.gravity * delta
    end

    if Input.GetSingleton():IsActionPressed("move_jump") and
            self.airborneTime < self.options.jumpForgiveness and
            not wasJumping then
        self.velocity = Vector3.UP * self:getJumpVelocity()
        ctx:SetState(MotionState.CharacterState.JUMPING)

        state:SetRagdoll(false)
    end

    -- Persist jump state until falling
    if wasJumping and self.velocity.y >= 0 and not state.isRagdoll then
        ctx:SetState(MotionState.CharacterState.JUMPING)
    end

    ctx.offset += self.velocity * delta

    -- Decide whether character is falling
    if state.isGrounded or state.isRagdoll then
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
                if not fallRayResult:Has("collider") then
                    ctx:SetState(MotionState.CharacterState.FALLING)
                end
            end
        end
    end
end

function PhysicalMotion.GetVelocity(self: PhysicalMotion): Vector3?
    return self.velocity
end

export type PhysicalMotion = typeof(PhysicalMotion.new())
return PhysicalMotion
