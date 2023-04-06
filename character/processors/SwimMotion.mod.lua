--[[
    Swimming.
]]

local MotionState = require("../MotionState.mod")
local Utils = require("../../utils/Utils.mod")
local PhysicalMotion = require("PhysicalMotion.mod")
local HorizontalMotion = require("HorizontalMotion.mod")
local Move = require("Move.mod")

local SwimMotion = setmetatable({
    ID = "swim",
}, MotionState.MotionProcessor)

SwimMotion.__index = SwimMotion

function SwimMotion.new()
    local self = {}

    self.options = {
        dragCoeff = 8,
    }

    return setmetatable(self, SwimMotion)
end

-- Returns if the player is submerged and if the player is touching water.
function SwimMotion.isInWater(self: SwimMotion, state: MotionState.MotionState)
    -- Try to avoid second test if no areas were found before with a bigger margin
    if #state.intersections.areas == 0 then
        return false, false, -1
    end

    -- Must conduct intersection test again with smaller margin to actually tell if player is underwater :(
    local intersectParams = PhysicsShapeQueryParameters3D.new()
    intersectParams.shape = state.mainCollisionShape
    intersectParams.transform = state.mainCollider.globalTransform
    intersectParams.collideWithBodies = false
    intersectParams.collideWithAreas = true
    intersectParams.margin = state.options.margin

    local intersectResult = state.GetWorld3D().directSpaceState:IntersectShape(intersectParams)

    local waterCollider: Area3D?
    for _, data: Dictionary in intersectResult do
        local area = data:Get("collider") :: Area3D
        if area:IsInGroup("water") then
            waterCollider = area
            break
        end
    end

    if not waterCollider then
        return false, false, -1
    end

    -- Check depth with ray
    local SUBMERSED_THRESH = 0.3 -- allowed distance from top of head to water while still considered submerged
    local MARGIN = 0.5
    local height = state.mainCollisionShape.height

    local rayParams = PhysicsRayQueryParameters3D.new()
    rayParams.from = state.mainCollider.globalTransform.origin + Vector3.UP * height / 2
    rayParams.to = rayParams.from + Vector3.DOWN * (height + MARGIN)
    rayParams.collideWithBodies = false
    rayParams.collideWithAreas = true

    local rayResult = state.GetWorld3D().directSpaceState:IntersectRay(rayParams)
    if not rayResult:IsEmpty() then
        -- Distance from top of character to surface
        local distAbove = (rayParams.from - rayResult:Get("position") :: Vector3).y
        if distAbove > height then
            return false, false, -1
        end

        if rayResult:Get("collider") == waterCollider then
            return distAbove < SUBMERSED_THRESH, true, distAbove
        end
    end

    return true, true, -1
end

function SwimMotion.Process(self: SwimMotion, state: MotionState.MotionState, delta: number)
    if state.isRagdoll then
        return
    end

    local ctx = state.ctx
    -- distAbove is the distance of the player's head above the water assuming it was upright.
    -- It's kind of intended that it doesn't account for rotation.
    local submerged, inWater, distAbove = self:isInWater(state)

    if not inWater then
        return
    end

    local MIN_JUMP_DIST_ABOVE = 0.2 -- min distAbove to jump
    if distAbove > MIN_JUMP_DIST_ABOVE and Utils.DoGameInput(state.node) and Input.singleton:IsActionPressed("move_jump") then
        -- Jump with the intent of exiting the water
        ctx.messages[PhysicalMotion.JUMP] = true
        return
    end

    -- Handle ladders in a somewhat passable way
    if state:IsState(MotionState.CharacterState.CLIMBING) then
        ctx.messages[Move.CANCEL_UPRIGHTING] = true
        ctx.messages[HorizontalMotion.CANCEL_ORIENT] = true
        ctx.newBasis = ctx.newBasis:Slerp(Utils.BasisUpright(ctx.newBasis), Utils.LerpWeight(delta, 1e-1))

        local CHECK_DIST = 2
        local snapParams = PhysicsTestMotionParameters3D.new()
        snapParams.from = Transform3D.new(ctx.newBasis, state.GetTransform().origin)
        snapParams.motion = ctx.camBasisFlat * ctx.inputDirection * CHECK_DIST
        snapParams.margin = state.options.margin

        local snapResult = PhysicsTestMotionResult3D.new()

        if state:TestMotion(snapParams, snapResult) then
            ctx:AddOffset(snapResult:GetTravel())
        end

        return
    end

    ctx.messages[PhysicalMotion.DRAG] = self.options.dragCoeff

    local targetBasis: Basis?

    if not ctx.inputDirection:IsZeroApprox() then
        -- Can swim if underwater or previously swimming and still in water
        local canSwim = submerged or
                (inWater and state:IsState(MotionState.CharacterState.SWIMMING) and not state:IsState(MotionState.CharacterState.IDLE))

        if canSwim and state.camera then
            ctx:SetState(MotionState.CharacterState.SWIMMING)

            ctx:CancelState(MotionState.CharacterState.WALKING)
            ctx.messages[HorizontalMotion.CANCEL_ORIENT] = true
            ctx:CancelProcessor(PhysicalMotion.ID)

            local movementBasis = Basis.new(Quaternion.new(Vector3.FORWARD, ctx.camBasisFlat * ctx.inputDirection):Normalized())

            if ctx.inputDirection:Dot(Vector3.FORWARD) > 0.9 then
                -- Essentially going only forward

                -- Prevent player from swimming too high
                local MAX_DIST_ABOVE = 0.8 -- max distAbove where player is allowed to swim by camera rotation
                local cameraAngleX = state.camera.cameraRotation.x -- negative when looking down
                if cameraAngleX > 0 and distAbove >= 0 and not state.isGrounded then
                    cameraAngleX *= math.clamp(1 - distAbove / MAX_DIST_ABOVE, 0, 1)
                end

                targetBasis = movementBasis * Basis.new(Vector3.RIGHT, -math.pi / 2 + cameraAngleX)

                -- ???
                ctx.messages[HorizontalMotion.MOVEMENT_DIRECTION] = movementBasis * Basis.new(Vector3.RIGHT, cameraAngleX) * Vector3.FORWARD
            else
                -- Any other direction
                targetBasis = movementBasis * Basis.new(Vector3.RIGHT, -math.pi / 2)

                -- Do a separate ray-based ground check which is more lenient and accounts for capsule shape causing undesired normal output
                local capsuleTransform = state.mainCollider.globalTransform
                local capsuleShape = state.mainCollisionShape
                local headPos = capsuleTransform.origin + capsuleTransform.basis.y * (capsuleShape.height / 2 - capsuleShape.radius)

                local checkDist = capsuleShape.radius + 0.5
                local groundRayParams = PhysicsRayQueryParameters3D.new()
                groundRayParams.from = headPos
                groundRayParams.to = headPos + Vector3.DOWN * checkDist

                local groundResult = state.GetWorld3D().directSpaceState:IntersectRay(groundRayParams)

                if not groundResult:IsEmpty() then
                    local actualNormal = groundResult:Get("normal") :: Vector3
                    local groundTransform = Basis.new(Quaternion.new(Vector3.UP, actualNormal):Normalized())
                    -- TODO: Luau 568: type hack
                    targetBasis = groundTransform * targetBasis :: Basis
                end
            end
        end
    elseif submerged then
        ctx:SetState(bit32.bor(MotionState.CharacterState.SWIMMING, MotionState.CharacterState.IDLE))
    end

    ctx.messages[Move.CANCEL_UPRIGHTING] = true
    -- Do uprighting but slower
    ctx.newBasis = ctx.newBasis:Slerp(targetBasis or Utils.BasisUpright(ctx.newBasis), Utils.LerpWeight(delta, 1e-2))
end

export type SwimMotion = typeof(SwimMotion.new())
return SwimMotion
