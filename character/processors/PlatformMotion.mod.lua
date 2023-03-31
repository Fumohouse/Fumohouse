--[[
    Responsible for moving the character when it is standing on a moving platform.
]]

local MotionState = require("../MotionState.mod")
local Utils = require("../../utils/Utils.mod")

local PlatformMotion = setmetatable({
    ID = "platform",
}, MotionState.MotionProcessor)

PlatformMotion.__index = PlatformMotion

function PlatformMotion.new()
    local self = {}

    self.linearVelocity = Vector3.ZERO
    self.angularVelocity = 0
    self.options = {
        dragCoeff = 0.01
    }

    return setmetatable(self, PlatformMotion)
end

function PlatformMotion.Process(self: PlatformMotion, state: MotionState.MotionState, delta: number)
    if state.isRagdoll then
        self.linearVelocity = Vector3.ZERO
        self.angularVelocity = 0
        return
    end

    local ctx = state.ctx

    if state.isGrounded then
        local bodyState = assert(PhysicsServer3D.singleton:BodyGetDirectState(state.groundRid))

        self.linearVelocity = bodyState:GetVelocityAtLocalPosition(
            state.GetTransform().origin - bodyState.transform.origin
        )

        self.angularVelocity = bodyState.angularVelocity.y
    else
        -- Physically imprecise but probably good enough (and better than nothing)
        self.linearVelocity = Utils.ApplyDrag(self.linearVelocity, self.options.dragCoeff, delta)
        self.angularVelocity = move_toward(self.angularVelocity, 0, self.options.dragCoeff * self.angularVelocity)
    end

    ctx:AddOffset(self.linearVelocity * delta)
    ctx.newBasis = ctx.newBasis:Rotated(Vector3.UP, self.angularVelocity * delta)
end

function PlatformMotion.GetVelocity(self: PlatformMotion): Vector3?
    return self.linearVelocity
end

export type PlatformMotion = typeof(PlatformMotion.new())
return PlatformMotion
