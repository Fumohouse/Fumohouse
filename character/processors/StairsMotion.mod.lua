--[[
    Responsible for allowing the character to navigate stairs/steps.
]]

local MotionState = require("../MotionState.mod")

local StairsMotion = setmetatable({
    ID = "stairs",
}, MotionState.MotionProcessor)

StairsMotion.__index = StairsMotion

local MAX_STEP_MARGIN = 0.01

function StairsMotion.new()
    local self = {}

    self.foundStair = false

    self.beginPosition = Vector3.ZERO
    self.endPosition = Vector3.ZERO

    self.motionVector = Vector3.ZERO
    self.wallTangent = Vector3.ZERO
    -- I have no idea how to describe this. It's the flattened normal from the side of the stair, pointing in the direction of motion
    -- (i.e. opposite of the original normal for upstairs, same as original for downstairs)
    self.stairNormal = Vector3.ZERO
    self.slopeNormal = Vector3.ZERO

    self.options = {
        maxStepAngle = 3,
        minStepHeight = 0.01,
        maxStepHeight = 0.5,
        slopeDistance = 1,
    }

    return setmetatable(self, StairsMotion)
end

function StairsMotion.reset(self: StairsMotion, state: MotionState.MotionState)
    self.foundStair = false

    self.beginPosition = Vector3.ZERO
    self.endPosition = Vector3.ZERO

    self.motionVector = Vector3.ZERO
    self.wallTangent = Vector3.ZERO
    self.stairNormal = Vector3.ZERO
    self.slopeNormal = Vector3.ZERO

    state.groundOverride[StairsMotion.ID] = nil
end

function StairsMotion.HandleCancel(self: StairsMotion, state: MotionState.MotionState)
    self:reset(state)
end

function StairsMotion.isValidStair(self: StairsMotion, normal: Vector3)
    return normal:AngleTo(Vector3.UP) <= math.rad(self.options.maxStepAngle)
end

function StairsMotion.normalTest(self: StairsMotion, state: MotionState.MotionState, from: Transform3D, motion: Vector3): (PhysicsTestMotionResult3D?, Vector3?)
    local searchParams = PhysicsTestMotionParameters3D.new()
    searchParams.from = from
    searchParams.motion = motion
    searchParams.maxCollisions = 4
    searchParams.recoveryAsCollision = true
    searchParams.margin = state.options.margin

    local searchResult = PhysicsTestMotionResult3D.new()
    local searchFound = state:TestMotion(searchParams, searchResult)
    if not searchFound then
        return
    end

    local wallNormal = searchResult:GetCollisionNormal()
    wallNormal = Vector3.new(wallNormal.x, 0, wallNormal.z):Normalized()

    -- Can happen if original normal is somehow vertical
    if wallNormal:IsZeroApprox() then
        return
    end

    return searchResult, wallNormal
end

function StairsMotion.findStepUp(self: StairsMotion, state: MotionState.MotionState): (Vector3?, Vector3?)
    local characterTransform = state.GetTransform()
    local forward = -characterTransform.basis.z

    -- 2x in case we are facing a bit diagonal compared to the step wall normal
    local checkDistance = self.options.slopeDistance * 2 - state.mainCollisionShape.radius
    local searchResult, wallNormal = self:normalTest(state, characterTransform, forward * checkDistance)
    if searchResult and wallNormal then
        -- Distance to step
        local distance = -wallNormal:Dot(searchResult:GetTravel()) + state.mainCollisionShape.radius
        if distance > self.options.slopeDistance then
            return
        end

        local highestPoint = Vector3.ZERO

        for i = 0, searchResult:GetCollisionCount() - 1 do
            local point = searchResult:GetCollisionPoint(i)

            if point.y > highestPoint.y then
                local stepHeight = point.y - characterTransform.origin.y
                if stepHeight > self.options.maxStepHeight + MAX_STEP_MARGIN or
                        stepHeight < self.options.minStepHeight then
                    return
                end

                highestPoint = point
            end
        end

        -- Use ray to find true position of target point
        -- and to check the step's top normal
        local RAY_MARGIN = 0.01
        local RAY_DISTANCE = 0.1

        local rayParams = PhysicsRayQueryParameters3D.new()
        rayParams.from = highestPoint
            - wallNormal * RAY_MARGIN
            + Vector3.UP * RAY_DISTANCE

        rayParams.to = rayParams.from + Vector3.DOWN * (RAY_DISTANCE + RAY_MARGIN)

        local rayResult = state.GetWorld3D().directSpaceState:IntersectRay(rayParams)
        if not rayResult:Has("normal") or not self:isValidStair(rayResult:Get("normal") :: Vector3) then
            return
        end

        local targetPoint = Vector3.new(highestPoint.x, (rayResult:Get("position") :: Vector3).y, highestPoint.z)

        -- "Straighten" to wall normal
        local motion = targetPoint - characterTransform.origin
        targetPoint = characterTransform.origin
            + wallNormal * motion:Dot(wallNormal)
            + Vector3.UP * motion.y

        return targetPoint, -wallNormal
    end

    return
end

function StairsMotion.findStepDown(self: StairsMotion, state: MotionState.MotionState): (Vector3?, Vector3?)
    local characterTransform = state.GetTransform()
    local directSpaceState = state.GetWorld3D().directSpaceState

    -- Fire a series of rays to determine slope end position
    local forward = -characterTransform.basis.z
    local maxDistance = self.options.slopeDistance * 2
    local rayMotion = Vector3.DOWN * (self.options.maxStepHeight + MAX_STEP_MARGIN)

    local STEP_SIZE = 0.1
    local MIN_STEP_MARGIN = 0.1 -- Account for grounding distance

    local targetPosition: Vector3?

    for i = 0, maxDistance, STEP_SIZE do
        local checkRayParams = PhysicsRayQueryParameters3D.new()
        checkRayParams.from = characterTransform.origin + forward * i
        checkRayParams.to = checkRayParams.from + rayMotion

        local checkRayResult = directSpaceState:IntersectRay(checkRayParams)
        if not checkRayResult:Has("normal") or not self:isValidStair(checkRayResult:Get("normal") :: Vector3) then
            break
        end

        local pos = checkRayResult:Get("position") :: Vector3

        if characterTransform.origin.y - pos.y < self.options.minStepHeight + MIN_STEP_MARGIN then
            return
        end

        if targetPosition and not is_equal_approx(pos.y, targetPosition.y) then
            break
        end

        targetPosition = pos
    end

    if targetPosition then
        -- Subtract radius (to account for motion test) then add 2 * radius (to account for player on edge, etc.)
        local checkDistance = maxDistance + state.mainCollisionShape.radius
        local searchTransform = Transform3D.new(characterTransform.basis, targetPosition + Vector3.UP * MIN_STEP_MARGIN)
        local searchResult, wallNormal = self:normalTest(state, searchTransform, -forward * checkDistance)

        if searchResult and wallNormal then
            local motion = targetPosition - characterTransform.origin

            -- Down into the step instead of away from it
            if motion:Dot(wallNormal) < 0 then
                return
            end

            -- Straighten, fix size of slope to maximum size
            targetPosition = characterTransform.origin
                + wallNormal * math.min(motion:Dot(wallNormal), self.options.slopeDistance)
                + Vector3.UP * motion.y

            return targetPosition, wallNormal
        end
    end

    return
end

function StairsMotion.applyMotion(self: StairsMotion, state: MotionState.MotionState, delta: number, targetPoint: Vector3, stairNormal: Vector3)
    local characterTransform = state.GetTransform()

    self.beginPosition = characterTransform.origin
    self.endPosition = targetPoint
    self.foundStair = true

    -- As a vector, points "AWAY"
    local totalMotion = self.endPosition - self.beginPosition

    -- totalMotion as components of DOWN and stairNormal (ignore side to side)
    self.motionVector = (stairNormal * totalMotion:Dot(stairNormal)
        + Vector3.DOWN * totalMotion:Dot(Vector3.DOWN)):Normalized()

    -- Points "RIGHT"
    self.wallTangent = Vector3.UP:Cross(-stairNormal)
    self.stairNormal = stairNormal
    self.slopeNormal = self.wallTangent:Cross(self.motionVector):Normalized()

    -- Rely on HorizontalMotion to walk up the slope using just the normal
    state.groundOverride[StairsMotion.ID] = self.slopeNormal
end

function StairsMotion.handleStairs(self: StairsMotion, state: MotionState.MotionState, delta: number)
    local ctx = state.ctx

    -- Don't look for new stair unless player is moving and recently on the ground
    if not self.foundStair and (ctx.inputDirection:LengthSquared() == 0 or state:IsState(MotionState.CharacterState.FALLING)) then
        return false
    end

    local targetPointUp, stairNormalUp = self:findStepUp(state)
    if targetPointUp and stairNormalUp then
        self:applyMotion(state, delta, targetPointUp, stairNormalUp)
        return true
    end

    local targetPointDown, stairNormalDown = self:findStepDown(state)
    if targetPointDown and stairNormalDown then
        self:applyMotion(state, delta, targetPointDown, stairNormalDown)
        return true
    end

    return false
end

function StairsMotion.Process(self: StairsMotion, state: MotionState.MotionState, delta: number)
    if not self:handleStairs(state, delta) then
        self:reset(state)
    end
end

export type StairsMotion = typeof(StairsMotion.new())
return StairsMotion
