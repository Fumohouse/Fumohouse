--- @class
--- @extends AnimatableBody3D
local RotatingBody  = {}
local RotatingBodyC = gdclass(RotatingBody)

export type RotatingBody = AnimatableBody3D & typeof(RotatingBody) & {
    --- @property
    --- @range 0 60 1 degrees
    rotationSpeed: number,
}

--- @registerMethod
function RotatingBody._PhysicsProcess(self: RotatingBody, delta: number)
    self:RotateY(math.rad(self.rotationSpeed) * delta)
end

return RotatingBodyC
