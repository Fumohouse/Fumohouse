--[[
    Responsible for moving the character when it is standing on a moving platform.
]]

local Character = require("scenes/character/Character")

local PlatformMotion = setmetatable({
    ID = "platform",
}, Character.CharacterMotion)

PlatformMotion.__index = PlatformMotion

function PlatformMotion.new(): PlatformMotion
    local self = {}

    self.linearVelocity = Vector3.ZERO
    self.angularVelocity = 0
    self.options = {
        dragCoeff = 0.005
    }

    return setmetatable(self, PlatformMotion)
end

function PlatformMotion.ProcessMotion(self: PlatformMotion, ctx: Character.MotionContext, delta: number)
    local character = ctx.character

    if character.isGrounded then
        local bodyState = assert(PhysicsServer3D.GetSingleton():BodyGetDirectState(character.groundRid))

        self.linearVelocity = bodyState:GetVelocityAtLocalPosition(
            character.globalPosition - bodyState.transform.origin
        )

        self.angularVelocity = bodyState.angularVelocity.y
    else
        -- Physically imprecise but probably good enough (and better than nothing)
        self.linearVelocity = self.linearVelocity:MoveToward(Vector3.ZERO, self.options.dragCoeff * self.linearVelocity:Length())
        self.angularVelocity = move_toward(self.angularVelocity, 0, self.options.dragCoeff * self.angularVelocity)
    end

    ctx.offset += self.linearVelocity * delta
    ctx.angularOffset += self.angularVelocity * delta
end

export type PlatformMotion = typeof(PlatformMotion.new())
return PlatformMotion
