local RotatingBodyImpl = {}
local RotatingBody = gdclass(nil, AnimatableBody3D)
    :RegisterImpl(RotatingBodyImpl)

export type RotatingBody = AnimatableBody3D & typeof(RotatingBodyImpl) & {
    rotationSpeed: number,
}

RotatingBody:RegisterProperty("rotationSpeed", {
    type = Enum.VariantType.FLOAT,
    hint = Enum.PropertyHint.RANGE,
    hintString = "0,60,1,degrees"
})

function RotatingBodyImpl._PhysicsProcess(self: RotatingBody, delta: number)
    self:RotateY(math.rad(self.rotationSpeed) * delta)
end

RotatingBody:RegisterMethodAST("_PhysicsProcess")

return RotatingBody
