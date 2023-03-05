--[[
    Responsible for handling ladder climbing.
]]

local Character = require("../Character")
local HorizontalMotion = require("HorizontalMotion.mod")
local PhysicalMotion = require("PhysicalMotion.mod")
local StairsMotion = require("StairsMotion.mod")

local LadderMotion = setmetatable({
    ID = "ladder",
}, Character.CharacterMotion)

LadderMotion.__index = LadderMotion

function LadderMotion.new(): LadderMotion
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

function LadderMotion.ProcessMotion(self: LadderMotion, ctx: Character.MotionContext, delta: number)
    local character = ctx.character
    if #character.walls == 0 then
        return
    end

    local collideParams = PhysicsShapeQueryParameters3D.new()
    collideParams.shape = character.capsule
    collideParams.transform = character.collider.globalTransform
    collideParams.collideWithAreas = true
    collideParams.collideWithBodies = false

    local directSpaceState = character:GetWorld3D().directSpaceState
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

        local charFwd = -character.globalTransform.basis.z
        if charFwd:AngleTo(ladderFwd) > math.rad(self.options.maxAngle) then
            return
        end

        -- Check if any walls match the ladder (descendant and normal alignment)
        local wallFound = false

        for _, wall in character.walls do
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
                self.isMoving = true
            elseif math.abs(math.pi - movementAngle) < math.rad(self.options.maxAngle) then
                self.velocity *= -1

                -- Since we are going backwards, cancel horiz. motion to avoid breaking.
                -- (and to avoid WALKING state)
                -- Check for the ground in case we are at a safe distance to break anyway
                local groundParams = PhysicsRayQueryParameters3D.new()
                groundParams.from = character.globalPosition
                groundParams.to = groundParams.from + Vector3.DOWN * self.options.breakHeight

                local groundResult = directSpaceState:IntersectRay(groundParams)

                if not groundResult:Has("normal") or not character:IsStableGround(groundResult:Get("normal") :: Vector3) then
                    ctx:CancelProcessor(HorizontalMotion.ID)
                end

                self.isMoving = true
            end
        end

        ctx.offset += self.velocity * delta

        ctx:CancelProcessor(PhysicalMotion.ID)
        ctx:CancelProcessor(StairsMotion.ID)

        -- WALKING doesn't make sense here, but its processor is still run under some circumstances
        ctx:CancelState(Character.CharacterState.WALKING)

        ctx:SetState(Character.CharacterState.CLIMBING)
    end
end

function LadderMotion.GetVelocity(self: LadderMotion): Vector3?
    return self.velocity
end

export type LadderMotion = typeof(LadderMotion.new())
return LadderMotion
