--[[
    Responsible for moving the character when it is standing on a moving platform.
]]

local MotionState = require("../MotionState.mod")
local Utils = require("../../utils/Utils.mod")

local PlatformMotion = { ID = "platform" }
PlatformMotion.__index = PlatformMotion

function PlatformMotion.new()
    local self = {}

    self.velocity = Vector3.ZERO
    self.angularVelocity = 0
    self.options = {
        dragCoeff = 0.01
    }

    return setmetatable(self, PlatformMotion)
end

function PlatformMotion.Process(self: PlatformMotion, state: MotionState.MotionState, delta: number)
    if state.isRagdoll then
        self.velocity = Vector3.ZERO
        self.angularVelocity = 0
        return
    end

    local ctx = state.ctx

    if state.isGrounded then
        local bodyState = assert(PhysicsServer3D.singleton:BodyGetDirectState(state.groundRid))

        self.velocity = bodyState:GetVelocityAtLocalPosition(
            state.node.position - bodyState.transform.origin
        )

        self.angularVelocity = bodyState.angularVelocity.y
    else
        -- Physically imprecise but probably good enough (and better than nothing)
        self.velocity = Utils.ApplyDrag(self.velocity, self.options.dragCoeff, delta)
        self.angularVelocity = move_toward(self.angularVelocity, 0, self.options.dragCoeff * self.angularVelocity)
    end

    ctx:AddOffset(self.velocity * delta)
    ctx.newBasis = ctx.newBasis:Rotated(Vector3.UP, self.angularVelocity * delta)
end

function PlatformMotion.GetVelocity(self: PlatformMotion): Vector3?
    return self.velocity
end

function PlatformMotion.GetState(self: PlatformMotion)
    local state = Dictionary.new()

    state:Set("v", self.velocity)
    state:Set("av", self.angularVelocity)

    return state
end

function PlatformMotion.LoadState(self: PlatformMotion, state: Variant)
    assert(typeof(state) == "Dictionary")

    if state:Has("v") then
        local val = state:Get("v")
        assert(typeof(val) == "Vector3")
        self.velocity = val
    end

    if state:Has("av") then
        local val = state:Get("av")
        assert(typeof(val) == "number")
        self.angularVelocity = val
    end
end

export type PlatformMotion = typeof(PlatformMotion.new())
return PlatformMotion
