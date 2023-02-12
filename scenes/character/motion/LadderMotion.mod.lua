--[[
    Responsible for handling ladder climbing.
]]

local Character = require("scenes/character/Character")
local HorizontalMotion = require("scenes/character/motion/HorizontalMotion.mod")
local PhysicalMotion = require("scenes/character/motion/PhysicalMotion.mod")
local StairsMotion = require("scenes/character/motion/StairsMotion.mod")

local LadderMotion = setmetatable({
    ID = "ladder",
}, Character.CharacterMotion)

LadderMotion.__index = LadderMotion

function LadderMotion.new(): LadderMotion
    local self = {}

    self.isMoving = false
    self.options = {
        forwardVelocity = 8,
        climbVelocity = 8,
        maxAngle = 30,
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

        -- Check if the ladder forward direction matches any walls
        local wallFound = false

        for _, wall in character.walls do
            local ANGLE_MARGIN = 0.1

            -- Compare to flat vector
            local compareNormal = Vector3.new(-wall.normal.x, 0, -wall.normal.z):Normalized()

            if compareNormal:AngleTo(ladderFwd) < ANGLE_MARGIN then
                wallFound = true
                break
            end
        end

        if not wallFound then
            return
        end

        local charFwd = -character.globalTransform.basis.z
        if charFwd:AngleTo(ladderFwd) > math.rad(self.options.maxAngle) then
            return
        end

        local directionFlat = ctx.camBasisFlat * ctx.inputDirection
        local movementAngle = directionFlat:AngleTo(ladderFwd)

        self.isMoving = false

        if directionFlat:LengthSquared() > 0 then
            local offset = ladderBasis.y * self.options.climbVelocity * delta

            if movementAngle < math.rad(self.options.maxAngle) then
                -- Add a forward velocity to make the exit (at the top) much smoother
                ctx.offset += offset + ladderFwd * self.options.forwardVelocity * delta
                self.isMoving = true
            elseif math.abs(math.pi - movementAngle) < math.rad(self.options.maxAngle) then
                ctx.offset -= offset

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

        ctx:CancelProcessor(PhysicalMotion.ID)
        ctx:CancelProcessor(StairsMotion.ID)

        -- WALKING doesn't make sense here, but its processor is still run under some circumstances
        ctx:CancelState(Character.CharacterState.WALKING)

        ctx:SetState(Character.CharacterState.CLIMBING)
    end
end

export type LadderMotion = typeof(LadderMotion.new())
return LadderMotion
