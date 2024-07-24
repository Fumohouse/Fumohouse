--- @class
--- @extends PathFollow3D
local PathFollower = {}
local PathFollowerC = gdclass(PathFollower)

export type PathFollower = PathFollow3D & typeof(PathFollower) & {
    --- @property
    --- @range 0 10
    speed: number,
}

--- @registerMethod
function PathFollower._PhysicsProcess(self: PathFollower, delta: number)
    self.progress += self.speed * delta
end

return PathFollowerC
