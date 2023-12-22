--[[
    Detects and stores the character's contacts.
]]

local MotionState = require("../MotionState.mod")

local Intersections = { ID = "intersections" }
Intersections.__index = Intersections

function Intersections.new()
    local self = {}
    return setmetatable(self, Intersections)
end

function Intersections.Process(self: Intersections, state: MotionState.MotionState, delta: number)
    local MARGIN = 0.1

    -- Walls
    local wallParams = PhysicsTestMotionParameters3D.new()
    wallParams.from = state.node.globalTransform
    wallParams.motion = Vector3.ZERO
    wallParams.margin = MARGIN
    wallParams.recoveryAsCollision = true
    wallParams.maxCollisions = 4

    local wallResult = PhysicsTestMotionResult3D.new()
    state:TestMotion(wallParams, wallResult)

    table.clear(state.walls)
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

    -- Intersections
    table.clear(state.intersections.bodies)
    table.clear(state.intersections.areas)

    local intersectParams = PhysicsShapeQueryParameters3D.new()
    intersectParams.shape = state.mainCollisionShape
    intersectParams.collisionMask = state.node.collisionMask
    intersectParams.transform = state.mainCollider.globalTransform
    intersectParams.collideWithAreas = true
    intersectParams.collideWithBodies = true
    intersectParams.margin = MARGIN

    local exclude = Array.new()
    exclude:PushBack(state.rid)
    intersectParams.exclude = exclude

    local intersectResult = state.node:GetWorld3D().directSpaceState:IntersectShape(intersectParams)

    for _, data: Dictionary in intersectResult do
        local collider = data:Get("collider") :: Object

        if collider:IsA(Area3D) then
            table.insert(state.intersections.areas, collider :: Area3D)
        elseif collider:IsA(CollisionObject3D) then
            table.insert(state.intersections.bodies, collider :: CollisionObject3D)
        end
    end
end

export type Intersections = typeof(Intersections.new())
return Intersections
