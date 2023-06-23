--- @class
--- @extends EditorScenePostImport
--- @tool
--- @permissions INTERNAL
local PostImportGltf = {}
local PostImportGltfC = gdclass(PostImportGltf)

--- @classType PostImportGltf
export type PostImportGltf = EditorScenePostImport & typeof(PostImportGltf) & {
    convertedMaterials: {[number]: ShaderMaterial}
}

local PROPERTY_MAP = {
	["albedo_color"] = "albedo",
	["albedo_texture"] = "texture_albedo",
	["ao_light_affect"] = "ao_light_affect",
	["ao_texture"] = "texture_ambient_occlusion",
	-- ao_texture_channel: special behavior
	["emission"] = "emission",
	["emission_energy"] = "emission_energy",
	["metallic"] = "metallic",
	["metallic_specular"] = "specular",
	["metallic_texture"] = "texture_metallic",
	-- metallic_texture_channel: special behavior
	["normal_scale"] = "normal_scale",
	["normal_texture"] = "texture_normal",
	["roughness"] = "roughness",
	["roughness_texture"] = "texture_roughness",
	["uv1_offset"] = "uv1_offset",
	["uv1_scale"] = "uv1_scale",
}

local TEXTURE_MASKS = {
    Vector4.new(1, 0, 0, 0),
    Vector4.new(0, 1, 0, 0),
    Vector4.new(0, 0, 1, 0),
    Vector4.new(0, 0, 0, 1),
    Vector4.new(0.3333333, 0.3333333, 0.3333333, 0),
}

function PostImportGltf._Init(self: PostImportGltf)
    self.convertedMaterials = {}
end

local function getTextureMask(channel: ClassEnumBaseMaterial3D_TextureChannel)
	return TEXTURE_MASKS[channel + 1]
end

function PostImportGltf.convertMaterial(self: PostImportGltf, mat: StandardMaterial3D)
    local id = mat:GetInstanceId()

    if self.convertedMaterials[id] then
        return self.convertedMaterials[id]
    end

    local newMat = (assert(load("res://resources/materials/gltf_dither_material.tres")) :: ShaderMaterial)
        :Duplicate()

    for from, to in pairs(PROPERTY_MAP) do
        newMat:SetShaderParameter(to, mat:Get(from))
    end

    newMat:SetShaderParameter("ao_texture_channel", getTextureMask(mat.aoTextureChannel))
    newMat:SetShaderParameter("metallic_texture_channel", getTextureMask(mat.metallicTextureChannel))
    newMat.resourceLocalToScene = true

    self.convertedMaterials[id] = newMat
    return newMat
end

function PostImportGltf.iterate(self: PostImportGltf, node: Node)
    if node:IsA(MeshInstance3D) then
        local meshInst = node :: MeshInstance3D
        local mesh = assert(meshInst.mesh)

        for i = 0, mesh:GetSurfaceCount() - 1 do
            local material = assert(mesh:SurfaceGetMaterial(i))
            if material:IsA(StandardMaterial3D) then
                mesh:SurfaceSetMaterial(i, self:convertMaterial(material :: StandardMaterial3D))
            end
        end
    end

    for _, child: Node in node:GetChildren() do
        self:iterate(child)
    end
end

--- @registerMethod
function PostImportGltf._PostImport(self: PostImportGltf, scene: Node): Object
    self:iterate(scene)
    return scene
end

return PostImportGltfC
