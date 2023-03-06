--[[
    Responsible for allowing the character to navigate stairs/steps.
]]

local MotionState = require("../MotionState.mod")

local StairsMotion = setmetatable({
    ID = "stairs",
}, MotionState.MotionProcessor)

StairsMotion.__index = StairsMotion

function StairsMotion.new()
    local self = {}

    self.foundStair = false

    self.beginPosition = Vector3.ZERO
    self.endPosition = Vector3.ZERO

    self.motionVector = Vector3.ZERO
    self.wallTangent = Vector3.ZERO
    self.wallNormal = Vector3.ZERO
    self.slopeNormal = Vector3.ZERO

    self.velocity = Vector3.ZERO

    self.options = {
        maxStepAngle = 3,
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
    self.wallNormal = Vector3.ZERO
    self.slopeNormal = Vector3.ZERO

    self.velocity = Vector3.ZERO

    state.groundOverride[StairsMotion.ID] = nil
end

function StairsMotion.HandleCancel(self: StairsMotion, state: MotionState.MotionState)
    self:reset(state)
end

function StairsMotion.handleStairs(self: StairsMotion, state: MotionState.MotionState, delta: number)
    local MAX_STEP_MARGIN = 0.01

    local ctx = state.ctx
    local characterTransform = state.GetTransform()

    -- Don't look for new stair unless player is moving and on the ground
    if not self.foundStair and (ctx.inputDirection:LengthSquared() == 0 or state:IsState(MotionState.CharacterState.FALLING)) then
        return false
    end

    -- Search for the stair
    local capsuleRadius = state.mainCollisionShape.radius
    local forward = -characterTransform.basis.z

    -- 2x in case we are facing a bit diagonal compared to the step wall normal
    local checkDistance = (self.options.slopeDistance - capsuleRadius) * 2

    local searchParams = PhysicsTestMotionParameters3D.new()
    searchParams.from = characterTransform
    searchParams.motion = forward * checkDistance
    searchParams.maxCollisions = 4
    searchParams.recoveryAsCollision = true
    searchParams.margin = state.options.margin

    local searchResult = PhysicsTestMotionResult3D.new()
    local searchFound = state:TestMotion(searchParams, searchResult)

    if not searchFound then
        return false
    end

    local highestIdx = 0
    local highestPoint = Vector3.ZERO

    local MIN_STEP_HEIGHT = 0.01

    for i = 0, searchResult:GetCollisionCount() - 1 do
        local point = searchResult:GetCollisionPoint(i)

        if point.y > highestPoint.y then
            local stepHeight = point.y - characterTransform.origin.y
            if stepHeight > self.options.maxStepHeight + MAX_STEP_MARGIN or
                    stepHeight < MIN_STEP_HEIGHT then
                return false
            end

            highestIdx = i
            highestPoint = point
        end
    end

    local wallNormal = searchResult:GetCollisionNormal(highestIdx)
    wallNormal = Vector3.new(wallNormal.x, 0, wallNormal.z):Normalized()

    -- Cancel if turned away from the step
    if -wallNormal:Dot(forward) < 0.5 then
        return false
    end

    -- Distance to step
    local distance = -wallNormal:Dot(searchResult:GetTravel()) + capsuleRadius
    if distance > self.options.slopeDistance then
        return false
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
    if not rayResult:Has("normal") or
            (rayResult:Get("normal") :: Vector3):AngleTo(Vector3.UP) > math.rad(self.options.maxStepAngle) then
        return false
    end

    local targetPoint = Vector3.new(highestPoint.x, (rayResult:Get("position") :: Vector3).y, highestPoint.z)

    -- Constantly recompute positions to avoid issues with, e.g. spinning platforms regarded as stairs
    local isNewStair = not self.foundStair or not is_equal_approx(targetPoint.y, self.endPosition.y)
    local prevMotion = if isNewStair then
        targetPoint - characterTransform.origin
    else
        -- Maintain previous height and distance if stair matches
        self.endPosition - self.beginPosition

    local prevNormal = if isNewStair then wallNormal else self.wallNormal

    self.beginPosition = targetPoint
        + Vector3.DOWN * prevMotion.y
        - wallNormal * prevMotion:Dot(prevNormal)
    self.endPosition = targetPoint
    self.foundStair = true

    -- As a vector, points "AWAY"
    local totalMotion = self.endPosition - self.beginPosition

    -- totalMotion as components of DOWN and wallNormal (ignore side to side)
    self.motionVector = (-wallNormal * totalMotion:Dot(-wallNormal)
        + Vector3.DOWN * totalMotion:Dot(Vector3.DOWN)):Normalized()

    -- Points "RIGHT"
    self.wallTangent = Vector3.UP:Cross(wallNormal)
    self.wallNormal = wallNormal
    self.slopeNormal = self.wallTangent:Cross(self.motionVector):Normalized()

    state.groundOverride[StairsMotion.ID] = self.slopeNormal

    -- Position on the capsule which should contact the virtual slope
    local contactPosition = characterTransform.origin
        + Vector3.UP * capsuleRadius
        - self.slopeNormal * capsuleRadius

    local horizDistance = (contactPosition - self.beginPosition):Dot(-wallNormal)
    local totalDistance = (self.endPosition - self.beginPosition):Dot(-wallNormal)

    local currentTarget = lerp(self.beginPosition.y, self.endPosition.y, horizDistance / totalDistance)
    local offset = Vector3.UP * (currentTarget - contactPosition.y)
    ctx.offset += offset
    self.velocity = offset / delta

    return true
end

function StairsMotion.Process(self: StairsMotion, state: MotionState.MotionState, delta: number)
    if not self:handleStairs(state, delta) then
        self:reset(state)
    end
end

function StairsMotion.GetVelocity(self: StairsMotion): Vector3?
    return self.velocity
end

export type StairsMotion = typeof(StairsMotion.new())
return StairsMotion
