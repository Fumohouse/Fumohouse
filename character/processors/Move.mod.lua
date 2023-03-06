--[[
    Responsible for moving and rotating the character.
    Pushes objects when they are in the way.
]]

local MotionState = require("../MotionState.mod")

local Move = setmetatable({
    ID = "move",
}, MotionState.MotionProcessor)

Move.__index = Move

function Move.new()
    local self = {}

    self.options = {
        pushForce = 70,
    }

    return setmetatable(self, Move)
end

function Move.Process(self: Move, state: MotionState.MotionState, delta: number)
    local MAX_SLIDES = 5

    local origPos = state.GetTransform().origin
    local slides = 0

    local remaining = state.ctx.offset

    while slides < MAX_SLIDES and remaining:LengthSquared() > 1e-3 do
        local result = state.MoveAndCollide(remaining, state.options.margin)
        if result then
            local normal = result:GetNormal()
            local rid = result:GetColliderRid()

            if MotionState.ShouldPush(rid) then
                -- TODO: If moving faster than a certain velocity (i.e. related to movement velocity),
                -- apply traditional collision resolution (impulse, etc.)
                -- https://www.euclideanspace.com/physics/dynamics/collision/threed/index.htm

                local bodyState = assert(PhysicsServer3D.GetSingleton():BodyGetDirectState(rid))

                bodyState:ApplyForce(
                    remaining:Normalized() * self.options.pushForce,
                    result:GetPosition() - bodyState.transform.origin
                )
            end

            remaining = result:GetRemainder():Slide(normal)
            slides += 1
        else
            break
        end
    end

    local newPos = state.GetTransform().origin
    state.velocity = (newPos - origPos) / delta
    state.SetTransform(Transform3D.new(state.ctx.newBasis:Orthonormalized(), newPos))
end

export type Move = typeof(Move.new())
return Move
