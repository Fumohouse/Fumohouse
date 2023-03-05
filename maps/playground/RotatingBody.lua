local RotatingBodyImpl = {}
local RotatingBody = gdclass(nil, AnimatableBody3D)
    :RegisterImpl(RotatingBodyImpl)

type RotatingBodyT = {
    rotationSpeed: number,
}

export type RotatingBody = AnimatableBody3D & RotatingBodyT & typeof(RotatingBodyImpl)

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
