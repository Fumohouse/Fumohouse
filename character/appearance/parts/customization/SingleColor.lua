local PartCustomizer = require("PartCustomizer")

local Appearance = require("../../Appearance")

local SingleColorImpl = {}
local SingleColor = gdclass(nil, PartCustomizer)
    :RegisterImpl(SingleColorImpl)

type SingleColor = PartCustomizer.PartCustomizer & typeof(SingleColorImpl) & {
    defaultColor: Color,
    mesh: string,
    meshInstance: MeshInstance3D?,
}

SingleColor:RegisterProperty("defaultColor", Enum.VariantType.COLOR)

SingleColor:RegisterProperty("mesh", Enum.VariantType.NODE_PATH)
    :NodePath(MeshInstance3D)

function SingleColorImpl._Ready(self: SingleColor)
    if self.mesh ~= "" then
        self.meshInstance = self:GetNode(self.mesh) :: MeshInstance3D
    end
end

SingleColor:RegisterMethod("_Ready")

function SingleColorImpl.Update(self: SingleColor, appearance: Appearance.Appearance, config: Dictionary?)
    if self.meshInstance then
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
    else
        push_warning("This single colored part has no linked mesh.")
    end
end

return SingleColor
