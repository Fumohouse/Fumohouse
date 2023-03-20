--[[
    Responsible for moving and rotating the character.
    Performs recovery when the character is intersecting other objects.
    Pushes objects when they are in the way.
]]

local Utils = require("../../utils/Utils.mod")
local MotionState = require("../MotionState.mod")

local Move = setmetatable({
    ID = "move",
}, MotionState.MotionProcessor)

Move.__index = Move

function Move.new()
    local self = {}

    self.options = {
        pushForce = 70,
    }

    return setmetatable(self, Move)
end

function Move.HandleCancel(self: Move, state: MotionState.MotionState)
    state.velocity = Vector3.ZERO
end

function Move.move(self: Move, state: MotionState.MotionState, motion: Vector3, from: Vector3, basis: Basis, delta: number)
    local params = PhysicsTestMotionParameters3D.new()
    params.margin = state.options.margin

    local result = PhysicsTestMotionResult3D.new()

    local slides = 0
    local remaining = motion
    local newPos = from
    local recovery: Vector3?

    local MAX_SLIDES = 5

    while (slides < MAX_SLIDES and remaining:LengthSquared() > 1e-3) or
            -- Add an extra slide when not ragdolling for recovery
            (not state.isRagdoll and slides == 0) do
        params.from = Transform3D.new(basis, newPos)
        params.motion = remaining

        local didCollide = state:TestMotion(params, result)

        if didCollide then
            local normal = result:GetCollisionNormal()
            local rid = result:GetColliderRid()

            -- Physics system pain
            local travel = result:GetTravel()
            local motionNormal = remaining:Normalized()
            local projectedMotion = motionNormal * travel:Dot(motionNormal)

            local actualMotion = projectedMotion
            local thisRecovery = travel - projectedMotion

            if not (remaining - projectedMotion):IsZeroApprox() then
                -- If we are trying to move, passing recovery on to the slow, interpolated handler is a bad idea.
                -- It may cause important motion (e.g. gravity) to get stuck. So, perform full recovery immediately.
                actualMotion += thisRecovery
                recovery = Vector3.ZERO
            else
                recovery = thisRecovery
            end

            if not state.isRagdoll and not (state.isGrounded and rid == state.groundRid) and MotionState.ShouldPush(rid) then
                -- TODO: If moving faster than a certain velocity (i.e. related to movement velocity),
                -- apply traditional collision resolution (impulse, etc.)
                -- https://www.euclideanspace.com/physics/dynamics/collision/threed/index.htm

                local bodyState = assert(PhysicsServer3D.singleton:BodyGetDirectState(rid))

                bodyState:ApplyForce(
                    motionNormal * self.options.pushForce,
                    result:GetCollisionPoint() - bodyState.transform.origin
                )
            end

            newPos += actualMotion
            remaining -= actualMotion
            -- Sometimes normal is in the same direction as the motion (e.g. moving in the same direction as a platform touching the character).
            -- Don't bother sliding then, otherwise motion will be almost completely eliminated for no reason.
            local normalAng = normal:Dot(motionNormal)
            if normalAng < 0 and not is_equal_approx(normalAng, 0) then
                remaining = remaining:Slide(normal)
            end

            slides += 1
        else
            newPos += remaining
            break
        end
    end

    return newPos, recovery
end

function Move.Process(self: Move, state: MotionState.MotionState, delta: number)
    local ctx = state.ctx
    local origTransform = state.GetTransform()

    local newPos, recovery = self:move(state, ctx.offset, origTransform.origin, origTransform.basis, delta)

    -- Apply smooth recovery if move didn't need to apply it already.
    -- For recovery to work and not cause issues, terrain/in-world objects and the character should be on different physics layers.
    -- Terrain/in-world objects don't need to test for the character (the should exert forces on them).
    if recovery then
        newPos += recovery * Utils.LerpWeight(delta, 1e-10)
    end

    state.velocity = (newPos - origTransform.origin) / delta

    local targetBasis: Basis

    if state.isRagdoll then
        targetBasis = ctx.newBasis
    else
        -- Y rotation last to have correct orientation when standing up
        local basisUpright = Basis.FromEuler(Vector3.new(0, ctx.newBasis:GetEuler(Enum.EulerOrder.ZXY).y, 0))
        targetBasis = ctx.newBasis:Slerp(basisUpright, Utils.LerpWeight(delta, 1e-10))
    end

    state.SetTransform(Transform3D.new(targetBasis, newPos))
end

export type Move = typeof(Move.new())
return Move
