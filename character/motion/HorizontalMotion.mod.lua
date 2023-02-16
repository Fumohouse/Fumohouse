--[[
    Responsible for horizontal movement (i.e. WASD controls).
]]

local Character = require("../Character")
local CameraController = require("../CameraController")
local Utils = require("../../utils/Utils.mod")

local HorizontalMotion = setmetatable({
    ID = "horizontal",
}, Character.CharacterMotion)

HorizontalMotion.__index = HorizontalMotion

function HorizontalMotion.new(): HorizontalMotion
    local self = {}

    self.velocity = Vector3.ZERO
    self.options = {
        minSpeed = 0.1,
        movementSpeed = 10,
        movementAcceleration = 50,
    }

    return setmetatable(self, HorizontalMotion)
end

function HorizontalMotion.HandleCancel(self: HorizontalMotion, ctx: Character.MotionContext)
    self.velocity = Vector3.ZERO
end

function HorizontalMotion.ProcessMotion(self: HorizontalMotion, ctx: Character.MotionContext, delta: number)
    local character = ctx.character
    local directionFlat = ctx.camBasisFlat * ctx.inputDirection

    local slopeTransform = Basis.new(
        Quaternion.new(Vector3.UP, character.groundNormal)
    )
    local direction = slopeTransform * directionFlat

    local targetVelocity = direction * self.options.movementSpeed

    -- Handle transition between different ground (normals)
    if direction:LengthSquared() > 0 then
        self.velocity = self.velocity:Length() * direction
    end

    self.velocity = self.velocity:MoveToward(targetVelocity, delta * self.options.movementAcceleration)

    -- If we ran into a wall last frame, adjust velocity accordingly
    if #character.walls > 0 then
        local normal = character.walls[1].normal

        -- Only slide if we are trying to move into the wall
        local shouldSlide = direction:Dot(normal) < 0

        if shouldSlide then
            for i = 2, #character.walls do
                if not character.walls[i].normal:IsEqualApprox(normal) then
                    shouldSlide = false
                    break
                end
            end
        end

        if shouldSlide then
            self.velocity = self.velocity:Slide(normal)
        end
    end

    -- Update state
    if self.velocity:LengthSquared() > self.options.minSpeed * self.options.minSpeed and direction:LengthSquared() > 0 then
        ctx:SetState(Character.CharacterState.WALKING)
    end

    -- Update rotation
	-- The rigidbody should never be scaled, so scale is reset when setting basis.
    if character.camera and character.camera.cameraMode == CameraController.CameraMode.FIRST_PERSON then
        character.transform = Transform3D.new(
            ctx.camBasisFlat,
            character.globalPosition
        )
    elseif direction:LengthSquared() > 0 then
        local movementBasis = Basis.new(Quaternion.new(Vector3.FORWARD, directionFlat))

        -- Orthonormalize for floating point precision errors
        character.transform = Transform3D.new(
            character.transform.basis:Orthonormalized():Slerp(movementBasis, Utils.LerpWeight(delta)),
            character.globalPosition
        )
    end

    ctx.offset += self.velocity * delta
end

export type HorizontalMotion = typeof(HorizontalMotion.new())
return HorizontalMotion
