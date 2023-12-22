local Utils = {
    stageColor = Color.FromHsv(203 / 360, 1, 0.7),
    stageName = "Prototype",
    stageAbbrev = "PRO",
    version = "2023/03/01",
}

function Utils.GetBuildString()
    return `{Utils.stageName} {Utils.version}`
end

-- https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
function Utils.LerpWeight(delta: number, factor: number?)
    local factorA = if factor == nil then 5e-6 else factor
    return 1 - factorA ^ delta
end

function Utils.FormatVector3(vec: Vector3)
    return string.format("(%.2f %.2f %.2f)", vec.x, vec.y, vec.z)
end

function Utils.BasisUpright(basis: Basis)
    -- Y rotation last to have correct orientation when standing up
    return Basis.FromEuler(Vector3.new(0, basis:GetEuler(Enum.EulerOrder.ZXY).y, 0))
end

function Utils.ApplyDrag(vec: Vector3, coeff: number, delta: number)
    return vec:MoveToward(Vector3.ZERO, coeff * vec:Length() * delta)
end

function Utils.DoGameInput(self: Node)
    return self:GetViewport():GuiGetFocusOwner() == nil
end

-- https://github.com/godotengine/godot/blob/9d1cbab1c432b6f1d66ec939445bec68b6af519e/editor/plugins/node_3d_editor_plugin.cpp#L4091-L4121
function Utils.CalculateBounds(node: Node3D)
    local bounds = AABB.new()

    if node:IsA(VisualInstance3D) then
        bounds = (node :: VisualInstance3D):GetAabb()
    end

    for _, child in node:GetChildren() do
        if child:IsA(Node3D) then
            bounds = bounds:Merge(Utils.CalculateBounds(child))
        end
    end

    return node.transform * bounds
end

return Utils
