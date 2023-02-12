--[[
    Responsible for all motion which should be affected by gravity
    (falling, jumping, etc.)
]]

local Character = require("scenes/character/Character")

local PhysicalMotion = setmetatable({
    ID = "physical",
}, Character.CharacterMotion)

PhysicalMotion.__index = PhysicalMotion

function PhysicalMotion.new(): PhysicalMotion
    local self = {}

    self.velocity = Vector3.ZERO
    self.airborneTime = 0
    self.options = {
        gravity = 50,
        jumpHeight = 4.5,
        jumpForgiveness = 0.2, -- seconds

        -- FALLING state options
        fallingTime = 0.3,
        fallingAltitude = 2,
    }

    return setmetatable(self, PhysicalMotion)
end

-- TODO: Luau 562: Cannot use . operator since it will cause a type error
-- This is also done elsewhere. Check please
function PhysicalMotion:getJumpVelocity(): number
    -- Kinematics
    return math.sqrt(2 * self.options.gravity * self.options.jumpHeight)
end

function PhysicalMotion.HandleCancel(self: PhysicalMotion, ctx: Character.MotionContext)
    self.velocity = Vector3.ZERO
    self.airborneTime = 0
end

function PhysicalMotion.ProcessMotion(self: PhysicalMotion, ctx: Character.MotionContext, delta: number)
    local character = ctx.character
    local wasJumping = character:IsState(Character.CharacterState.JUMPING)

    if character.isGrounded and not wasJumping then
        self.velocity = Vector3.ZERO
    else
        self.velocity += Vector3.DOWN * self.options.gravity * delta
    end

    if Input.GetSingleton():IsActionPressed("move_jump") and
            self.airborneTime < self.options.jumpForgiveness and
            not wasJumping then
        self.velocity = Vector3.UP * self:getJumpVelocity()
        ctx:SetState(Character.CharacterState.JUMPING)
    end

    -- Persist jump state until falling
    if wasJumping and self.velocity.y >= 0 then
        ctx:SetState(Character.CharacterState.JUMPING)
    end

    ctx.offset += self.velocity * delta

    -- Decide whether character is falling
    if character.isGrounded then
        self.airborneTime = 0
    else
        self.airborneTime += delta

        if self.airborneTime > self.options.fallingTime and self.velocity.y < 0 then
            if character:IsState(Character.CharacterState.FALLING) then
                ctx:SetState(Character.CharacterState.FALLING)
            else
                local fallRayParams = PhysicsRayQueryParameters3D.new()
                fallRayParams.from = character.globalPosition
                fallRayParams.to = fallRayParams.from + Vector3.DOWN * self.options.fallingAltitude

                local fallRayResult = character:GetWorld3D().directSpaceState:IntersectRay(fallRayParams)
                if not fallRayResult:Has("collider") then
                    ctx:SetState(Character.CharacterState.FALLING)
                end
            end
        end
    end
end

export type PhysicalMotion = typeof(PhysicalMotion.new())
return PhysicalMotion
