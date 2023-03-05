local PathFollowerImpl = {}
local PathFollower = gdclass(nil, PathFollow3D)
    :RegisterImpl(PathFollowerImpl)

type PathFollowerT = {
    speed: number,
}

export type PathFollower = PathFollow3D & PathFollowerT & typeof(PathFollowerImpl)

PathFollower:RegisterProperty("speed", Enum.VariantType.FLOAT)
    :Range(0, 10)

function PathFollowerImpl._PhysicsProcess(self: PathFollower, delta: number)
    self.progress += self.speed * delta
end

PathFollower:RegisterMethodAST("_PhysicsProcess")

return PathFollower
