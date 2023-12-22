--[[
    Responsible for moving and rotating the character.
    Performs recovery when the character is intersecting other objects.
    Pushes objects when they are in the way.
]]

local Utils = require("../../utils/Utils.mod")
local MotionState = require("../MotionState.mod")

local Move = {
    ID = "move",
    CANCEL_UPRIGHTING = "cancelUprighting",

    UPRIGHTING_FACTOR = 5e-6,
}

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

function Move.customRecovery(self: Move, state: MotionState.MotionState, offset: Vector3)
    -- Based on Godot's builtin recovery (servers/physics_3d/godot_space_3d.cpp).
    -- The aim is to 1) make recovery primarily vertical unless absolutely necessary, and
    -- 2) to work around a Godot issue where contact pairs for the cylinder part of capsules
    -- in some colliders cause recovery to fail.

    if state.isRagdoll then
        return Vector3.ZERO
    end

    local exclude = Array.new()
    exclude:PushBack(state.rid)

    local params = PhysicsShapeQueryParameters3D.new()
    params.shape = state.mainCollisionShape
    params.collisionMask = state.node.collisionMask
    params.transform = state.mainCollider.globalTransform:Translated(offset)
    params.exclude = exclude

    local MAX_PAIRS = 16
    local result = state.node:GetWorld3D().directSpaceState:CollideShape(params, MAX_PAIRS)
    if result:Size() == 0 then
        return Vector3.ZERO
    end

    -- Find capsule cylinder transform
    local capsuleShape = state.mainCollisionShape
    local capsuleTransform = state.mainCollider.globalTransform:Translated(offset)
    local capsuleCylHeight = capsuleShape.height - 2 * capsuleShape.radius
    local capsuleCylBasePos = capsuleTransform.origin - capsuleTransform.basis.y * capsuleCylHeight / 2
    local capsuleCylTransform = Transform3D.new(capsuleTransform.basis, capsuleCylBasePos)
    local capsuleCylTransformInv = capsuleCylTransform:Inverse()

    local function isInsideCylinder(cylPos: Vector3)
        if cylPos.y < 0 or cylPos.y > capsuleCylHeight then
            return false
        end

        local MARGIN = 0.01
        return cylPos.x ^ 2 + cylPos.z ^ 2 <= (capsuleShape.radius + MARGIN) ^ 2
    end

    local recovery = Vector3.ZERO
    for i = 0, result:Size() - 1, 2 do
        local a = result:Get(i) :: Vector3
        local b = result:Get(i + 1) :: Vector3

        local cylA = capsuleCylTransformInv * a -- position local to cylinder
        local cylB = capsuleCylTransformInv * b

        -- Recompute points if necessary
        -- Mostly addresses both (1) and (2) above
        local minLen = capsuleShape.radius / 2
        if isInsideCylinder(cylA) and isInsideCylinder(cylB) and
                is_equal_approx(cylA.y, cylB.y) and
                -- When the points are close together, the player is close to the edge of the intersecting body.
                -- In that case, it's most likely that the horizontal movement is correct.
                (b - a):LengthSquared() > minLen ^ 2 then
            -- Recompute the pair to be vertical
            -- Assume this pair lies pretty much exactly on the ground
            local RAY_MARGIN = 0.01
            local rayParams = PhysicsRayQueryParameters3D.new()
            rayParams.from = b + Vector3.UP * RAY_MARGIN
            rayParams.to =  b + Vector3.DOWN * RAY_MARGIN
            rayParams.exclude = exclude

            local rayResult = state.node:GetWorld3D().directSpaceState:IntersectRay(rayParams)
            if not rayResult:IsEmpty() then
                local hitNormal = rayResult:Get("normal") :: Vector3
                -- If zero then the ray was inside the body it hit (happens often when being pushed by a wall)
                if not hitNormal:IsZeroApprox() then
                    local hitPos = rayResult:Get("position") :: Vector3
                    a = state.node.position + offset
                    b = Vector3.new(a.x, hitPos.y, a.z)
                end
            end
        end

        -- Compute recovery
        local direction = (b - a):Normalized() -- a to b
        -- Subtract recovery from b to avoid double counting certain contacts
        local depth = direction:Dot(b - recovery) - direction:Dot(a)

        if depth > 0 then
            recovery += direction * depth
        end
    end

    return recovery
end

function Move.move(self: Move, state: MotionState.MotionState, motion: Vector3, delta: number)
    local origTransform = state.node.globalTransform

    local params = PhysicsTestMotionParameters3D.new()
    params.margin = state.options.margin

    local result = PhysicsTestMotionResult3D.new()

    local slides = 0
    local remaining = motion
    local offset = Vector3.ZERO
    local recovery: Vector3?

    local MAX_SLIDES = 5

    while (slides < MAX_SLIDES and remaining:LengthSquared() > 1e-3) or
            -- Add an extra slide when not ragdolling for recovery
            (not state.isRagdoll and slides == 0) do
        params.from = origTransform:Translated(offset)
        params.motion = remaining

        local didCollide = state:TestMotion(params, result)
        if not didCollide then
            offset += remaining

            -- In case we are passing inside a body without detection
            if #state.intersections.bodies > 0 then
                recovery = self:customRecovery(state, offset)
            end

            break
        end

        local normal = result:GetCollisionNormal()
        local rid = result:GetColliderRid()

        -- Physics system pain
        local travel = result:GetTravel()
        local motionNormal = remaining:Normalized()
        local projectedMotion = motionNormal * travel:Dot(motionNormal)

        local actualMotion = projectedMotion
        local thisRecovery = travel - projectedMotion

        local MIN_CUSTOM_RECOVERY = 0.05

        if thisRecovery:LengthSquared() > MIN_CUSTOM_RECOVERY * MIN_CUSTOM_RECOVERY then
            -- Godot determined recovery was necessary, take advantage of their checks to perform custom recovery when necessary.
            local customRecovery = self:customRecovery(state, offset)

            if not (remaining - projectedMotion):IsZeroApprox() then
                -- If we are trying to move, passing recovery on to the slow, interpolated handler is a bad idea.
                -- It may cause important motion (e.g. gravity) to get stuck. So, perform full recovery immediately.
                actualMotion += customRecovery
                recovery = Vector3.ZERO
            else
                recovery = customRecovery
            end
        else
            -- Apply minimal recovery instantly
            actualMotion += thisRecovery
        end

        if not state.isRagdoll and not (state.isGrounded and rid == state.groundRid) and MotionState.ShouldPush(rid) then
            local bodyState = assert(PhysicsServer3D.singleton:BodyGetDirectState(rid))

            bodyState:ApplyForce(
                motionNormal * self.options.pushForce,
                result:GetCollisionPoint() - bodyState.transform.origin
            )
        end

        offset += actualMotion
        remaining -= actualMotion
        -- Sometimes normal is in the same direction as the motion (e.g. moving in the same direction as a platform touching the character).
        -- Don't bother sliding then, otherwise motion will be almost completely eliminated for no reason.
        local normalAng = normal:Dot(motionNormal)
        if normalAng < 0 and not is_equal_approx(normalAng, 0) then
            remaining = remaining:Slide(normal)
        end

        slides += 1
    end

    -- In case Godot completely fails to see recovery is needed
    if slides == MAX_SLIDES then
        offset += self:customRecovery(state, offset)
    end

    return offset, recovery
end

function Move.Process(self: Move, state: MotionState.MotionState, delta: number)
    local ctx = state.ctx
    local origTransform = state.node.globalTransform

    local offset, recovery = self:move(state, ctx.offset, delta)

    -- Apply smooth recovery if move didn't need to apply it already.
    -- For recovery to work and not cause issues, terrain/in-world objects and the character should be on different physics layers.
    -- Terrain/in-world objects don't need to test for the character (the should exert forces on them).
    if recovery then
        offset += recovery * Utils.LerpWeight(delta, 1e-10)
    end

    state.velocity = offset / delta

    local targetBasis: Basis

    if state.isRagdoll or ctx.messages[Move.CANCEL_UPRIGHTING] then
        targetBasis = ctx.newBasis
    else
        targetBasis = ctx.newBasis:Slerp(Utils.BasisUpright(ctx.newBasis), Utils.LerpWeight(delta, Move.UPRIGHTING_FACTOR))
    end

    state.node.globalTransform = Transform3D.new(targetBasis, origTransform.origin + offset)
end

export type Move = typeof(Move.new())
return Move
