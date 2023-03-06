--[[
    Responsible for handling ladder climbing.
]]

local MotionState = require("../MotionState.mod")
local HorizontalMotion = require("HorizontalMotion.mod")
local PhysicalMotion = require("PhysicalMotion.mod")
local StairsMotion = require("StairsMotion.mod")

local LadderMotion = setmetatable({
    ID = "ladder",
}, MotionState.MotionProcessor)

LadderMotion.__index = LadderMotion

function LadderMotion.new()
    local self = {}

    self.isMoving = false
    self.velocity = Vector3.ZERO

    self.options = {
        forwardVelocity = 8,
        climbVelocity = 8,
        maxAngle = 45,
        breakHeight = 0.5,
    }

    return setmetatable(self, LadderMotion)
end

function LadderMotion.Process(self: LadderMotion, state: MotionState.MotionState, delta: number)
    self.velocity = Vector3.ZERO

    if #state.walls == 0 then
        return
    end

    local ctx = state.ctx

    local collideParams = PhysicsShapeQueryParameters3D.new()
    collideParams.shape = state.mainCollisionShape
    collideParams.transform = state.mainCollider.globalTransform
    collideParams.collideWithAreas = true
    collideParams.collideWithBodies = false

    local directSpaceState = state.GetWorld3D().directSpaceState
    local result = directSpaceState:IntersectShape(collideParams)

    local ladder: Area3D?

    for _, data: Dictionary in result do
        local collider = data:Get("collider") :: Area3D

        if collider:IsInGroup("ladder") then
            ladder = collider
            break
        end
    end

    if ladder then
        local ladderBasis = ladder.globalTransform.basis
        local ladderFwd = -ladderBasis.z

        local characterTransform = state.GetTransform()

        local charFwd = -characterTransform.basis.z
        if charFwd:AngleTo(ladderFwd) > math.rad(self.options.maxAngle) then
            return
        end

        -- Check if any walls match the ladder (descendant and normal alignment)
        local wallFound = false

        for _, wall in state.walls do
            local ANGLE_MARGIN = 0.01

            local compareNormal = Vector3.new(-wall.normal.x, 0, -wall.normal.z):Normalized()

            if wall.collider:IsA(Node3D) and ladder:IsAncestorOf(wall.collider :: Node3D) and compareNormal:AngleTo(ladderFwd) < ANGLE_MARGIN then
                wallFound = true
                break
            end
        end

        if not wallFound then
            return
        end

        local directionFlat = ctx.camBasisFlat * ctx.inputDirection
        local movementAngle = directionFlat:AngleTo(ladderFwd)

        self.isMoving = false
        self.velocity = Vector3.ZERO

        if directionFlat:LengthSquared() > 0 then
            self.velocity = ladderBasis.y * self.options.climbVelocity

            if movementAngle < math.rad(self.options.maxAngle) then
                -- Add a forward velocity to make the exit (at the top) much smoother
                self.velocity += ladderFwd * self.options.forwardVelocity
            elseif math.abs(math.pi - movementAngle) < math.rad(self.options.maxAngle) then
                self.velocity *= -1

                -- Since we are going backwards, cancel horiz. motion to avoid breaking.
                -- Check for the ground in case we are at a safe distance to break anyway
                local groundParams = PhysicsRayQueryParameters3D.new()
                groundParams.from = characterTransform.origin
                groundParams.to = groundParams.from + Vector3.DOWN * self.options.breakHeight

                local groundResult = directSpaceState:IntersectRay(groundParams)

                if not groundResult:Has("normal") or not state:IsStableGround(groundResult:Get("normal") :: Vector3) then
                    ctx:CancelProcessor(HorizontalMotion.ID)
                end
            end

            self.isMoving = true
            ctx.offset += self.velocity * delta
        end

        ctx:CancelProcessor(PhysicalMotion.ID)
        ctx:CancelProcessor(StairsMotion.ID)

        -- WALKING doesn't make sense here, but its processor is still run under some circumstances
        ctx:CancelState(MotionState.CharacterState.WALKING)

        ctx:SetState(MotionState.CharacterState.CLIMBING)
    end
end

function LadderMotion.GetVelocity(self: LadderMotion): Vector3?
    return self.velocity
end

export type LadderMotion = typeof(LadderMotion.new())
return LadderMotion
