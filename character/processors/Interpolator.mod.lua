--[[
    Handles interpolating between current and authoritative state.
]]

local MotionState = require("../MotionState.mod")

local Interpolator = { ID = "interpolator" }
Interpolator.__index = Interpolator

function Interpolator.new()
    local self = {}

    self.state = (nil :: any) :: MotionState.MotionState -- :-)

    self.basisOffset = nil :: Basis?
    self.translateOffset = nil :: Vector3?
    self.progress = 0

    self.lastBasis = Basis.new()
    self.lastTranslate = Vector3.new()

    self.options = {
        time = 0.16,
        teleportThreshold = 3,
    }

    return setmetatable(self, Interpolator)
end

function Interpolator.Initialize(self: Interpolator, state: MotionState.MotionState)
    self.state = state
end

function Interpolator.Process(self: Interpolator, state: MotionState.MotionState, delta: number)
    local ctx = state.ctx

    if state.ctx.isReplay or not self.basisOffset or not self.translateOffset then
        return
    end

    self.progress = math.min(1, self.progress + delta / self.options.time)

    local newBasisOffset = Basis.IDENTITY:Slerp(self.basisOffset, self.progress)
    local newTranslateOffset = self.translateOffset * self.progress

    state.node.position += newTranslateOffset - self.lastTranslate
    -- This multiplication order seems odd but it works
    ctx.newBasis = ctx.newBasis * newBasisOffset * self.lastBasis:Inverse()

    self.lastBasis = newBasisOffset
    self.lastTranslate = newTranslateOffset

    if self.progress == 1 then
        self.basisOffset = nil
        self.translateOffset = nil
    end
end

function Interpolator.SetTarget(self: Interpolator, target: Transform3D)
    local globalTransform = self.state.node.globalTransform
    if globalTransform:IsEqualApprox(target) then
        return
    end

    local translateOffset = target.origin - globalTransform.origin
    if translateOffset:Length() > self.options.teleportThreshold then
        self.state.node.globalTransform = target
        return
    end

    self.basisOffset = globalTransform.basis:Inverse() * target.basis
    self.translateOffset = translateOffset
    self.progress = 0

    self.lastBasis = Basis.new()
    self.lastTranslate = Vector3.ZERO
end

export type Interpolator = typeof(Interpolator.new())

return Interpolator
