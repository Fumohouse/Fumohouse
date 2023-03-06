--[[
    Detects and stores the character's wall contacts.
]]

local MotionState = require("../MotionState.mod")

local Walls = setmetatable({
    ID = "walls",
}, MotionState.MotionProcessor)

Walls.__index = Walls

function Walls.new()
    local self = {}
    return setmetatable(self, Walls)
end

function Walls.Process(self: Walls, state: MotionState.MotionState, delta: number)
    table.clear(state.walls)

    local WALL_MARGIN = 0.1

    local wallParams = PhysicsTestMotionParameters3D.new()
    wallParams.from = state.GetTransform()
    wallParams.motion = Vector3.ZERO
    wallParams.margin = WALL_MARGIN
    wallParams.recoveryAsCollision = true
    wallParams.maxCollisions = 4

    local wallResult = PhysicsTestMotionResult3D.new()
    state:TestMotion(wallParams, wallResult)

    for i = 0, wallResult:GetCollisionCount() - 1 do
        local normal = wallResult:GetCollisionNormal(i)
        if not state:IsStableGround(normal) and not MotionState.ShouldPush(wallResult:GetColliderRid(i)) then
            table.insert(state.walls, {
                point = wallResult:GetCollisionPoint(i),
                normal = wallResult:GetCollisionNormal(i),
                collider = assert(wallResult:GetCollider(i))
            })
        end
    end
end

export type Walls = typeof(Walls.new())
return Walls
