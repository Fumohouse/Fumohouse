--[[
    Handles separating characters from other characters.
]]

local MotionState = require("../MotionState.mod")

local Character = require("../Character")

local Separator = { ID = "separator" }
Separator.__index = Separator

function Separator.new()
    local self = {}

    self.options = {
        separation = 1.25,
        threshold = 0.9,
    }

    return setmetatable(self, Separator)
end

function Separator.Process(self: Separator, state: MotionState.MotionState, delta: number)
    if state.isRagdoll then
        return
    end

    for _, body in state.intersections.bodies do
        if not body:IsA(Character) then
            continue
        end

        local offset = state.GetTransform().origin - body.position
        local offsetFlat = Vector3.new(offset.x, 0, offset.z)
        if offset:Length() > self.options.threshold then
            continue
        end

        local direction = offsetFlat:Normalized()

        if direction:LengthSquared() == 0 then
            local angle = math.random() * 2 * math.pi
            direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
        end

        state.ctx:AddOffset((self.options.separation - offsetFlat:Length()) * direction)
    end
end

export type Separator = typeof(Separator.new())

return Separator
