--[[
    Handles separating characters from other characters.
]]

local MotionState = require("../MotionState.mod")

local Separator = { ID = "separator" }
Separator.__index = Separator

function Separator.new()
    local self = {}

    self.options = {
        velocity = 5.0,
    }

    return setmetatable(self, Separator)
end

function Separator.Process(self: Separator, state: MotionState.MotionState, delta: number)
    if state.isRagdoll or state:IsRemoteCharacter() then
        return
    end

    local exclude = Array.new()
    exclude:PushBack(state.rid)

    local params = PhysicsShapeQueryParameters3D.new()
    params.shape = state.mainCollisionShape
    params.collisionMask = 2 -- other characters
    params.transform = state.mainCollider.globalTransform
    params.exclude = exclude

    local MAX_PAIRS = 16
    local result = state.node:GetWorld3D().directSpaceState:CollideShape(params, MAX_PAIRS)
    if result:Size() == 0 then
        return Vector3.ZERO
    end

    for i = 0, result:Size() - 1, 2 do
        local a = result:Get(i) :: Vector3
        local b = result:Get(i + 1) :: Vector3

        local direction = (b - a):Normalized()
        if direction:LengthSquared() == 0 or direction:Dot(Vector3.UP) > 0.9999 then
            -- Deterministic for server. Randomness would be nice but oh well
            local ANGLE = math.pi / 4
            direction = Vector3.new(math.cos(ANGLE), 0, math.sin(ANGLE))
        end

        state.ctx:AddOffset(self.options.velocity * delta * direction)
    end
end

export type Separator = typeof(Separator.new())

return Separator
