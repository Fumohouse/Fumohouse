local PathFollowerImpl = {}
local PathFollower = gdclass(nil, PathFollow3D)
    :RegisterImpl(PathFollowerImpl)

export type PathFollower = PathFollow3D & typeof(PathFollowerImpl) & {
    speed: number,
}

PathFollower:RegisterProperty("speed", Enum.VariantType.FLOAT)
    :Range(0, 10)

function PathFollowerImpl._PhysicsProcess(self: PathFollower, delta: number)
    self.progress += self.speed * delta
end

PathFollower:RegisterMethodAST("_PhysicsProcess")

return PathFollower
