--[[
    Updates the grounding state of the character.
]]

local MotionState = require("../MotionState.mod")

local Grounding = setmetatable({
    ID = "grounding",
}, MotionState.MotionProcessor)

Grounding.__index = Grounding

function Grounding.new()
    local self = {}

    self.options = {
        groundingDistance = 0.1,
    }

    return setmetatable(self, Grounding)
end

function Grounding.Process(self: Grounding, state: MotionState.MotionState, delta: number)
    local overrideKey, overrideNormal = next(state.groundOverride)
    if overrideKey then
        state.isGrounded = true
        state.groundNormal = overrideNormal
        return
    end

    local transform = state.GetTransform()

    local params = PhysicsTestMotionParameters3D.new()
    params.from = transform
    params.motion = Vector3.DOWN * self.options.groundingDistance
    params.margin = state.options.margin
    params.maxCollisions = 4

    local result = PhysicsTestMotionResult3D.new()
    local didCollide = state:TestMotion(params, result)

    local foundGround = false

    if didCollide then
        for i = result:GetCollisionCount() - 1, 0, -1 do
            local normal = result:GetCollisionNormal(i)

            if state:IsStableGround(normal) then
                foundGround = true
                state.isGrounded = true
                state.groundRid = result:GetColliderRid(i)
                state.groundNormal = normal
            end
        end

        local shouldSnap = not state.isRagdoll and state:IsState(MotionState.CharacterState.JUMPING)

        if foundGround and shouldSnap then
            -- dot to account for any possible horiz. movement due to depenetration
            local offset = Vector3.UP * Vector3.UP:Dot(result:GetTravel())
            if offset:LengthSquared() > state.options.margin ^ 2 then
                state.ctx:AddOffset(offset * (1 - state.options.margin))
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
