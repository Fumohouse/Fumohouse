local PartCustomizer = require("PartCustomizer")

local Appearance = require("../../Appearance")

--- @class
--- @extends PartCustomizer
local SingleColor = {}
local SingleColorC = gdclass(SingleColor)

--- @classType SingleColor
type SingleColor = PartCustomizer.PartCustomizer & typeof(SingleColor) & {
    --- @property
    defaultColor: Color,

    --- @property
    mesh: NodePathConstrained<MeshInstance3D>,

    meshInstance: MeshInstance3D?,
}

--- @registerMethod
function SingleColor._Ready(self: SingleColor)
    if self.mesh ~= "" then
        self.meshInstance = self:GetNode(self.mesh) :: MeshInstance3D
    end
end

function SingleColor.Update(self: SingleColor, appearance: Appearance.Appearance, config: Dictionary?)
    if not self.meshInstance then
        push_warning("This single colored part has no linked mesh.")
        return
    end

    local material = assert(self.meshInstance:GetActiveMaterial(0))
    local color = if config and config:Has("color") then
        config:Get("color") :: Color
    else
        self.defaultColor

    if material:IsA(StandardMaterial3D) then
        (material :: StandardMaterial3D).albedoColor = color
    elseif material:IsA(ShaderMaterial) then
        local shaderMat = material :: ShaderMaterial

        if shaderMat:GetShaderParameter("albedo") ~= nil then
            shaderMat:SetShaderParameter("albedo", color)
        end
    end
end

return SingleColorC
