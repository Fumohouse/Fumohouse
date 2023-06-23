local Dock = require("Dock")

--- @class
--- @extends Button
--- @tool
--- @permissions INTERNAL
local BlenderTransform = {}
local BlenderTransformC = gdclass(BlenderTransform)

--- @classType BlenderTransform
export type BlenderTransform = Button & typeof(BlenderTransform) & {
    selection: EditorSelection,
}

--- @registerMethod
function BlenderTransform._Ready(self: BlenderTransform)
    local plugin = (self:GetNode("../..") :: Dock.Dock).plugin
    self.selection = plugin:GetEditorInterface():GetSelection()

    self.pressed:Connect(Callable.new(self, "_OnPressed"))
end

local function parseTransforms(str: string)
    local transforms = {}
    local lines = string.split(str, "\n")

    for _, line in lines do
        assert(string.sub(line, 1, 1) == "\"", "Invalid transform string (expected '\"').")

        local i = 2
        local objName = ""

        do
            -- Parse name
            local escape = false

            while i <= #line do
                local c = string.sub(line, i, i)

                if escape then
                    objName ..= c
                    escape = false
                elseif c == "\\" then
                    escape = true
                elseif c == "\"" then
                    i += 1
                    break
                else
                    objName ..= c
                end

                i += 1
            end
        end

        assert(string.sub(line, i, i) == "(", "Invalid transform string (expected opening '(').")
        assert(string.sub(line, #line) == ")", "Invalid transform string (expected closing ')').")
        i += 1

        local nums = {}
        for _, num in string.split(string.sub(line, i, #line - 1), ",") do
            local asNum = tonumber(num)
            assert(asNum, "Invalid transform string (failed to parse number).")
            table.insert(nums, asNum)
        end

        assert(#nums == 16, "Invalid transform string (expected 16 transform components).")

        --[[
            x    y    z    trns
            [01] [02] [03] [04]
            [05] [06] [07] [08]
            [09] [10] [11] [12]
            [13] [14] [15] [16]
        ]]

        -- What?
        local origin = Vector3.new(nums[4], nums[12], -nums[8])
        local basisOrig = Basis.new(
            Vector3.new(nums[1], nums[5], nums[9]),
            Vector3.new(nums[2], nums[6], nums[10]),
            Vector3.new(nums[3], nums[7], nums[11])
        )

        local eulerOrig = basisOrig:GetEuler()
        local euler = Vector3.new(eulerOrig.x, eulerOrig.z, -eulerOrig.y)

        local scaleOrig = basisOrig:GetScale()
        local scale = Vector3.new(scaleOrig.x, scaleOrig.z, scaleOrig.y)

        transforms[objName] = Transform3D.new(Basis.FromEuler(euler):Scaled(scale), Vector3.ZERO):Translated(origin)

        i += 1
    end

    return transforms
end

--- @registerMethod
function BlenderTransform._OnPressed(self: BlenderTransform)
    local selected = self.selection:GetSelectedNodes()
    if selected:IsEmpty() then
        return
    end

    local clipboard = DisplayServer.singleton:ClipboardGet()

    local transforms = parseTransforms(clipboard)

    for _, node: Node in selected do
        if not node:IsA(Node3D) then
            continue
        end

        if transforms[node.name] then
            (node :: Node3D).globalTransform = transforms[node.name]
        else
            push_warning(`No matching Blender object found for Node '{node.name}'.`)
        end
    end
end

return BlenderTransformC
