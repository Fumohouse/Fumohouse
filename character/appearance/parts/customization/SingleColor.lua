local PartCustomizer = require("PartCustomizer")

local Appearance = require("../../Appearance")

--- @class
--- @extends PartCustomizer
local SingleColor = {}
local SingleColorC = gdclass(SingleColor)

type SingleColor = PartCustomizer.PartCustomizer & typeof(SingleColor) & {
    --- @property
    defaultColor: Color,

    --- @property
    mesh: MeshInstance3D?,
}

function SingleColor.Update(self: SingleColor, appearance: Appearance.Appearance, config: Dictionary?)
    if not self.mesh then
        push_warning("This single colored part has no linked mesh.")
        return
    end

    local material = assert(self.mesh:GetActiveMaterial(0))
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
