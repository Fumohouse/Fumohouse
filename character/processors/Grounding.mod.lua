--[[
    Updates the grounding state of the character.
]]

local MotionState = require("../MotionState.mod")

local Grounding = {
    ID = "grounding",
    GROUND_OVERRIDE = "groundOverride",
}

Grounding.__index = Grounding

function Grounding.new()
    local self = {}

    self.options = {
        groundingDistance = 0.1,
    }

    return setmetatable(self, Grounding)
end

function Grounding.Process(self: Grounding, state: MotionState.MotionState, delta: number)
    local overrideNormal = state.ctx.messages[Grounding.GROUND_OVERRIDE] :: Vector3?
    if overrideNormal then
        state.isGrounded = true
        state.groundNormal = overrideNormal
        return
    end

    local transform = state.node.globalTransform

    local params = PhysicsTestMotionParameters3D.new()
    params.from = transform
    params.motion = Vector3.DOWN * self.options.groundingDistance
    params.margin = state.options.margin
    params.maxCollisions = 4

    local result = PhysicsTestMotionResult3D.new()

    local foundGround = false

    if state:TestMotion(params, result) then
        for i = result:GetCollisionCount() - 1, 0, -1 do
            local normal = result:GetCollisionNormal(i)

            if state:IsStableGround(normal) then
                foundGround = true
                state.isGrounded = true
                state.groundRid = result:GetColliderRid(i)
                state.groundNormal = normal
            end
        end

        local shouldSnap = not state.isRagdoll and is_equal_approx(state.ctx.offset.y, 0)

        if foundGround and shouldSnap then
            local MAX_UP_SNAP = 0.01

            -- dot to account for any possible horiz. movement due to depenetration
            local snapLength = Vector3.DOWN:Dot(result:GetTravel())
            if math.abs(snapLength) > state.options.margin and snapLength > -MAX_UP_SNAP then
                state.ctx:AddOffset(Vector3.DOWN * snapLength * (1 - state.options.margin))
            end
        end
    end

    if not foundGround then
        state.isGrounded = false
        state.groundNormal = Vector3.ZERO
    end
end

export type Grounding = typeof(Grounding.new())
return Grounding
