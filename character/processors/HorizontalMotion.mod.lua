--[[
    Responsible for horizontal movement (i.e. WASD controls).
]]

local MotionState = require("../MotionState.mod")
local CameraController = require("../CameraController")
local Utils = require("../../utils/Utils.mod")
local PhysicalMotion = require("PhysicalMotion.mod")

local HorizontalMotion = setmetatable({
    ID = "horizontal",
    CANCEL_ORIENT = "cancelOrient",
    MOVEMENT_DIRECTION = "movementDirection",
}, MotionState.MotionProcessor)

HorizontalMotion.__index = HorizontalMotion

function HorizontalMotion.new()
    local self = {}

    self.velocity = Vector3.ZERO
    self.options = {
        minSpeed = 0.1,
        walkSpeed = 8,
        runSpeed = 12,
        movementAcceleration = 50,
    }

    return setmetatable(self, HorizontalMotion)
end

function HorizontalMotion.HandleCancel(self: HorizontalMotion, state: MotionState.MotionState)
    self.velocity = Vector3.ZERO
end

function HorizontalMotion.Process(self: HorizontalMotion, state: MotionState.MotionState, delta: number)
    if state.isRagdoll then
        self.velocity = Vector3.ZERO
        return
    end

    local ctx = state.ctx

    local directionFlat = ctx.camBasisFlat * ctx.inputDirection
    local direction = ctx.messages[HorizontalMotion.MOVEMENT_DIRECTION] :: Vector3?

    if not direction then
        local slopeTransform = Basis.new(Quaternion.new(Vector3.UP, state.groundNormal):Normalized()) -- default to slope transform
        direction = slopeTransform * directionFlat
    end

    -- TODO: Luau 568: type hack
    assert(direction)

    local targetSpeed = if Utils.DoGameInput(state.node) and Input.singleton:IsActionPressed("move_run") then self.options.runSpeed else self.options.walkSpeed
    local targetVelocity = direction * targetSpeed

    if direction:LengthSquared() > 0 then
        -- Handle transition between different ground (normals)
        self.velocity = self.velocity:Length() * direction

        -- Update state
        ctx:SetState(MotionState.CharacterState.WALKING)
    end

    self.velocity = self.velocity:MoveToward(targetVelocity, delta * self.options.movementAcceleration)

    local drag = ctx.messages[PhysicalMotion.DRAG] :: number?
    if drag then
        self.velocity = Utils.ApplyDrag(self.velocity, drag, delta)
    end

    if not ctx.messages[HorizontalMotion.CANCEL_ORIENT] then
        -- Update rotation
        -- The rigidbody should never be scaled, so scale is reset when setting basis.
        if state.camera and state.camera.cameraMode == CameraController.CameraMode.FIRST_PERSON then
            ctx.newBasis = ctx.camBasisFlat
        elseif direction:LengthSquared() > 0 then
            local movementBasis = Basis.new(Quaternion.new(Vector3.FORWARD, directionFlat))
            ctx.newBasis = ctx.newBasis:Slerp(movementBasis, Utils.LerpWeight(delta))
        end
    end

    ctx:AddOffset(self.velocity * delta)
end

function HorizontalMotion.GetVelocity(self: HorizontalMotion): Vector3?
    return self.velocity
end

export type HorizontalMotion = typeof(HorizontalMotion.new())
return HorizontalMotion
