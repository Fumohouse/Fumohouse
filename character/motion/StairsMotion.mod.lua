--[[
    Responsible for allowing the character to navigate stairs/steps.
]]

local Character = require("../Character")

local StairsMotion = setmetatable({
    ID = "stairs",
}, Character.CharacterMotion)

StairsMotion.__index = StairsMotion

local OVERRIDE_KEY = "step_slope"

function StairsMotion.new(): StairsMotion
    local self = {}

    self.foundStair = false

    self.beginPosition = Vector3.ZERO
    self.endPosition = Vector3.ZERO

    self.motionVector = Vector3.ZERO
    self.wallTangent = Vector3.ZERO
    self.slopeNormal = Vector3.ZERO

    self.options = {
        maxStepAngle = 3,
        maxStepHeight = 0.5,
        slopeDistance = 1,
    }

    return setmetatable(self, StairsMotion)
end

function StairsMotion:reset(character: Character.Character)
    self.foundStair = false

    self.beginPosition = Vector3.ZERO
    self.endPosition = Vector3.ZERO

    self.motionVector = Vector3.ZERO
    self.wallTangent = Vector3.ZERO
    self.slopeNormal = Vector3.ZERO

    character.groundOverride[OVERRIDE_KEY] = nil
end

function StairsMotion.HandleCancel(self: StairsMotion, ctx: Character.MotionContext)
    self:reset(ctx.character)
end

function StairsMotion:handleStairs(ctx: Character.MotionContext): boolean
    -- TODO: Luau 562: Type hacks in this method

    local MAX_STEP_MARGIN = 0.01

    local character = ctx.character

    -- Cancel if we are falling or can't find the ground
    if character:IsState(Character.CharacterState.FALLING) then
        return false
    end

    -- Separate ground check with `maxStepHeight` instead of grounding distance
    local groundCheckParams = PhysicsTestMotionParameters3D.new()
    groundCheckParams.from = character.globalTransform
    groundCheckParams.motion = Vector3.DOWN * (self.options.maxStepHeight :: number)

    local foundGround = character:TestMotion(groundCheckParams)
    if not foundGround then
        return false
    end

    -- Search for the stair
    local capsuleRadius = character.capsule.radius
    local forward = -character.globalTransform.basis.z

    -- 2x in case we are facing a bit diagonal compared to the step wall normal
    local checkDistance = (self.options.slopeDistance :: number - capsuleRadius) * 2

    local searchParams = PhysicsTestMotionParameters3D.new()
    searchParams.from = character.globalTransform
    searchParams.motion = forward * checkDistance
    searchParams.maxCollisions = 4
    searchParams.recoveryAsCollision = true
    searchParams.margin = character.margin

    local searchResult = PhysicsTestMotionResult3D.new()
    local searchFound = character:TestMotion(searchParams, searchResult)

    if not searchFound then
        return false
    end

    local highestIdx = 0
    local highestPoint = Vector3.ZERO

    local MIN_STEP_HEIGHT = 0.01

    for i = 0, searchResult:GetCollisionCount() - 1 do
        local point = searchResult:GetCollisionPoint(i)

        if point.y > highestPoint.y then
            local stepHeight = point.y - character.globalPosition.y
            if stepHeight > self.options.maxStepHeight :: number + MAX_STEP_MARGIN or
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

    local rayResult = character:GetWorld3D().directSpaceState:IntersectRay(rayParams)
    if not rayResult:Has("normal") or
            (rayResult:Get("normal") :: Vector3):AngleTo(Vector3.UP) > math.rad(self.options.maxStepAngle :: number) then
        return false
    end

    local targetPoint = Vector3.new(highestPoint.x, (rayResult:Get("position") :: Vector3).y, highestPoint.z)

    if not self.foundStair or not is_equal_approx(targetPoint.y, self.endPosition.y)  then
        self.foundStair = true
        self.beginPosition = character.globalPosition
        self.endPosition = targetPoint

        -- As a vector, points "AWAY"
        local totalMotion = self.endPosition - self.beginPosition
        -- TODO: WTF is this
        self.motionVector = (-wallNormal * totalMotion:Dot(-wallNormal)
            + Vector3.DOWN * totalMotion:Dot(Vector3.DOWN)):Normalized()

        -- Points "RIGHT"
        self.wallTangent = Vector3.UP:Cross(wallNormal)
        self.slopeNormal = self.wallTangent:Cross(self.motionVector):Normalized()

        character.groundOverride[OVERRIDE_KEY] = self.slopeNormal
    end

    -- Position on the capsule which should contact the virtual slope
    local contactPosition = character.globalPosition
        + Vector3.UP * capsuleRadius
        - self.slopeNormal * capsuleRadius

    local horizDistance = (contactPosition - self.beginPosition):Dot(-wallNormal)
    local totalDistance = (self.endPosition - self.beginPosition):Dot(-wallNormal)

    local currentTarget = lerp(self.beginPosition.y, self.endPosition.y, horizDistance / totalDistance)
    ctx.offset += Vector3.UP * (currentTarget - contactPosition.y)

    return true
end

function StairsMotion.ProcessMotion(self: StairsMotion, ctx: Character.MotionContext, delta: number)
    if not self:handleStairs(ctx) then
        self:reset(ctx.character)
    end
end

export type StairsMotion = typeof(StairsMotion.new())
return StairsMotion
