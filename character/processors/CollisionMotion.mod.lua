--[[
    Responsible for handling collisions with other rigidbodies.
]]

local MotionState = require("../MotionState.mod")
local Utils = require("../../utils/Utils.mod")

local CollisionMotion = { ID = "collision" }

CollisionMotion.__index = CollisionMotion

function CollisionMotion.new()
    local self = {}

    self.directBodyState = nil :: PhysicsDirectBodyState3D?
    self.velocity = Vector3.ZERO
    self.angularVelocity = Vector3.ZERO

    self.options = {
        resistForce = 70,
    }

    return setmetatable(self, CollisionMotion)
end

function CollisionMotion.Initialize(self: CollisionMotion, state: MotionState.MotionState)
    state.node.contactMonitor = true
    state.node.maxContactsReported = 16
    self.directBodyState = PhysicsServer3D.singleton:BodyGetDirectState(state.rid)
end

function CollisionMotion.HandleCancel(self: CollisionMotion, state: MotionState.MotionState)
    self.velocity = Vector3.ZERO
    self.angularVelocity = Vector3.ZERO
end

function CollisionMotion.Process(self: CollisionMotion, state: MotionState.MotionState, delta: number)
    if state:IsRemoteCharacter() then
        return
    end

    if state.isRagdoll then
        self.velocity = Vector3.ZERO
        self.angularVelocity = Vector3.ZERO
        return
    end

    assert(self.directBodyState)

    local ctx = state.ctx

    for i = 0, self.directBodyState:GetContactCount() - 1 do
        -- TODO: VERY fake physics
        -- inverseMass doesn't seem to work. hacks below
        local collider = assert(self.directBodyState:GetContactColliderObject(i))
        local position = self.directBodyState:GetContactLocalPosition(i)

        local normal = self.directBodyState:GetContactLocalNormal(i)
        local colliderMass = 1

        if collider:IsA(RigidBody3D) then
            local rb = collider :: RigidBody3D

            colliderMass = rb.mass
            rb:ApplyForce(-normal * self.options.resistForce)
        end

        -- The show must go on
        -- https://github.com/godotengine/godot/pull/73569
        -- local impulse = self.directBodyState:GetContactImpulse(i)
        local impulse = (self.directBodyState:GetContactColliderVelocityAtPosition(i):Project(normal)) * colliderMass

        local MAGIC_CORRECTION = 1.6

        -- https://github.com/godotengine/godot/blob/a311a4b162364d032b03ddf2a0e603ba40615ad7/servers/physics_3d/godot_body_3d.h#L227-L230
        self.velocity += impulse / state.node.mass * MAGIC_CORRECTION
        self.angularVelocity += self.directBodyState.inverseInertiaTensor * (position - self.directBodyState.centerOfMass):Cross(impulse)
    end

    ctx:AddOffset(self.velocity * delta)
    ctx.newBasis = Basis.FromEuler(self.angularVelocity * delta) * ctx.newBasis

    -- Pretty fake physics
    self.velocity = self.velocity:Lerp(Vector3.ZERO, Utils.LerpWeight(delta, 1e-3))
    self.angularVelocity = self.angularVelocity:Lerp(Vector3.ZERO, Utils.LerpWeight(delta, 1e-3))
end

function CollisionMotion.GetVelocity(self: CollisionMotion): Vector3?
    return self.velocity
end

function CollisionMotion.GetState(self: CollisionMotion)
    local state = Dictionary.new()

    state:Set("v", self.velocity)
    state:Set("av", self.angularVelocity)

    return state
end

function CollisionMotion.LoadState(self: CollisionMotion, state: Variant)
    assert(typeof(state) == "Dictionary")

    if state:Has("v") then
        local val = state:Get("v")
        assert(typeof(val) == "Vector3")
        self.velocity = val
    end

    if state:Has("av") then
        local val = state:Get("av")
        assert(typeof(val) == "Vector3")
        self.angularVelocity = val
    end
end

export type CollisionMotion = typeof(CollisionMotion.new())
return CollisionMotion