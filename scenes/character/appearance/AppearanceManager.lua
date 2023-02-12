local Appearance = require("scenes/character/appearance/Appearance")
local Character = require("scenes/character/Character")
local CameraController = require("scenes/character/CameraController")
local SinglePart = require("scenes/character/appearance/parts/SinglePart")
local MultiPart = require("scenes/character/appearance/parts/MultiPart")
local FaceDatabase = require("scenes/character/appearance/face/FaceDatabase")
local FacePartStyle = require("scenes/character/appearance/face/FacePartStyle")
local EyeStyle = require("scenes/character/appearance/face/EyeStyle")
local PartCustomizer = require("scenes/character/appearance/parts/customization/PartCustomizer")
local PartDatabase = require("scenes/character/appearance/parts/PartDatabase")

local AppearanceManagerImpl = {}
local AppearanceManager = gdclass(nil, "Node3D")
    :RegisterImpl(AppearanceManagerImpl)

type AttachedPartInfo = {
    nodes: {Node3D},
    materials: {Material},
}

type AppearanceManagerT = {
    appearance: Appearance.Appearance,
    cameraFadeBegin: number,
    cameraFadeEnd: number,

    character: Character.Character,
    rig: Node3D,
    skeleton: Skeleton3D,

    faceMaterial: ShaderMaterial,
    skinMaterial: ShaderMaterial,

    attachedParts: {[string]: AttachedPartInfo},
    baseCameraOffset: number,

    currScale: number,
    alpha: number,
}

export type AppearanceManager = Node3D & AppearanceManagerT & typeof(AppearanceManagerImpl)

AppearanceManagerImpl.ATTACHMENTS = {
    [SinglePart.Bone.TORSO] = "Torso",
    [SinglePart.Bone.HEAD] = "Head",
    [SinglePart.Bone.R_ARM] = "RArm",
    [SinglePart.Bone.L_ARM] = "LArm",
    [SinglePart.Bone.R_HAND] = "RHand",
    [SinglePart.Bone.L_HAND] = "LHand",
    [SinglePart.Bone.R_LEG] = "RLeg",
    [SinglePart.Bone.L_LEG] = "LLeg",
    [SinglePart.Bone.R_FOOT] = "RFoot",
    [SinglePart.Bone.L_FOOT] = "LFoot",
}

AppearanceManagerImpl.SIZES = {
    doll = 0.5,
    shinmy = 0.75,
    base = 1.0,
    deka = 3.0,
}

local transparentTex: Texture2D = assert(load("res://assets/textures/transparent.png"))
local faceMaterial: ShaderMaterial = assert(load("face/face_material.tres"))
local faceDatabase: FaceDatabase.FaceDatabase = assert(load("res://resources/face_database.tres"))

AppearanceManager:RegisterProperty("appearance", Enum.VariantType.OBJECT)
    :Resource("Resource")

AppearanceManager:RegisterProperty("cameraFadeBegin", Enum.VariantType.FLOAT)
    :Default(1.5)

AppearanceManager:RegisterProperty("cameraFadeEnd", Enum.VariantType.FLOAT)
    :Default(0.25)

function AppearanceManagerImpl._Init(obj: Node3D, tbl: AppearanceManagerT)
    tbl.attachedParts = {}
    tbl.baseCameraOffset = 0

    tbl.currScale = 1
    tbl.alpha = 1
end

function AppearanceManagerImpl.setAlpha(self: AppearanceManager, alpha: number)
    local ALPHA_PARAM = "alpha"

    if self.alpha == alpha then
        return
    end

    self.alpha = alpha

    if alpha == 0 then
        self.rig.visible = false
        self.visible = false
        return
    end

    self.rig.visible = true
    self.visible = true

    self.faceMaterial:SetShaderParameter(ALPHA_PARAM, alpha)
    self.skinMaterial:SetShaderParameter(ALPHA_PARAM, alpha)

    for _, info in self.attachedParts do
        for _, material in info.materials do
            if not material:IsClass("ShaderMaterial") then
                continue
            end

            local shaderMaterial = material :: ShaderMaterial
            if not shaderMaterial:GetShaderParameter(ALPHA_PARAM) then
                continue
            end

            shaderMaterial:SetShaderParameter(ALPHA_PARAM, alpha)
        end
    end
end

function AppearanceManagerImpl.loadScale(self: AppearanceManager)
    local sizeId = self.appearance.size
    assert(AppearanceManager.SIZES[sizeId], `Unknown size: {sizeId}`)

    self.currScale = AppearanceManager.SIZES[sizeId]

    local scaleVec = Vector3.ONE * self.currScale

    self.rig.scale = scaleVec
    self.rig.position = Vector3.ZERO

    self.character.collider.scale = scaleVec
    self.character.collider.position = Vector3.UP * self.character.capsule.height * self.currScale / 2

    if self.character.camera then
        self.character.camera.cameraOffset = self.baseCameraOffset * self.currScale
    end
end

function AppearanceManagerImpl._PhysicsProcess(self: AppearanceManager, _delta: number)
    if self.character.camera then
        if self.character.camera.cameraMode == CameraController.CameraMode.FIRST_PERSON then
            self:setAlpha(0)
            return
        end

        local distance = (
            self.character.camera.globalPosition - self.character.camera:GetFocalPoint()
        ):Length()

        local beginScaled = self.cameraFadeBegin * self.currScale
        local endScaled = self.cameraFadeEnd * self.currScale

        local alpha = (distance - endScaled) / (beginScaled - endScaled)
        alpha = math.clamp(alpha, 0, 1)

        self:setAlpha(alpha)
    end
end

AppearanceManager:RegisterMethodAST("_PhysicsProcess")

function AppearanceManagerImpl._OnCharacterCameraUpdated(self: AppearanceManager, camera: CameraController.CameraController)
    self.baseCameraOffset = camera.cameraOffset
    self:loadScale()
end

AppearanceManager:RegisterMethod("_OnCharacterCameraUpdated")
    :Args({ name = "camera", type = Enum.VariantType.OBJECT })

function AppearanceManagerImpl.setFaceTex(self: AppearanceManager, uniform: string, texture: Texture2D?)
    self.faceMaterial:SetShaderParameter(
        uniform,
        if texture then texture else transparentTex
    )
end

function AppearanceManagerImpl.loadFacePartStyle(self: AppearanceManager, getCb, styleName: string, uniform: string)
    local texture: Texture2D?

    if styleName ~= "" then
        local style: FacePartStyle.FacePartStyle? = getCb(faceDatabase, styleName)
        assert(style, `Failed to load face style: {styleName}`)

        texture = style.texture
    end

    self:setFaceTex(uniform, texture)
end

function AppearanceManagerImpl.loadFace(self: AppearanceManager)
    -- Eyebrow & mouth
    self:loadFacePartStyle(FaceDatabase.GetEyebrow, self.appearance.eyebrows, "brow_texture")
    self:loadFacePartStyle(FaceDatabase.GetMouth, self.appearance.mouth, "mouth_texture")

    -- Eyes
    local eyeName = self.appearance.eyes

    local eyeTexture: Texture2D?
    local shineTexture: Texture2D?
    local overlayTexture: Texture2D?

    if eyeName ~= "" then
        local style: EyeStyle.EyeStyle? = faceDatabase:GetEye(eyeName)
        assert(style, `Failed to load eye style: {eyeName}`)

        eyeTexture = style.eyes
        shineTexture = style.shine
        overlayTexture = style.overlay

        self.faceMaterial:SetShaderParameter(
            "eye_tint",
            if style.supportsRecoloring then self.appearance.eyesColor else Color.WHITE
        )
    end

    self:setFaceTex("eye_texture", eyeTexture)
    self:setFaceTex("shine_texture", shineTexture)
    self:setFaceTex("overlay_texture", overlayTexture)
end

function AppearanceManagerImpl.attachSingle(self: AppearanceManager, partInfo: SinglePart.SinglePart, config: Dictionary?): Node3D
    local node = (assert(load(SinglePart.BASE_PATH .. partInfo.scenePath)) :: PackedScene):Instantiate() :: Node3D

    local targetAtt = self:GetNode(AppearanceManager.ATTACHMENTS[partInfo.bone]) :: BoneAttachment3D
    targetAtt:AddChild(node)
    node.transform = partInfo.transform

    -- Call AFTER _Ready
    if node:IsScript(PartCustomizer) then
        (node :: PartCustomizer.PartCustomizer):_FHInitialize(config)
    end

    return node
end

local function searchMaterials(node: Node3D, list: {[Material]: true}): {[Material]: true}
    if node:IsClass("MeshInstance3D") then
        local meshInst = node :: MeshInstance3D
        local mesh = assert(meshInst.mesh)

        for i = 0, mesh:GetSurfaceCount() - 1 do
            local material = meshInst:GetActiveMaterial(i)
            if material and material.resourceLocalToScene then
                list[material] = true
            end
        end
    end

    for _, child: Node in node:GetChildren() do
        if child:IsClass("Node3D") then
            searchMaterials(child :: Node3D, list)
        end
    end

    return list
end

function AppearanceManagerImpl.attach(self: AppearanceManager, id: string, config: Dictionary?)
    if self.attachedParts[id] then
        return
    end

    local info = (_G["PartDatabase"] :: PartDatabase.PartDatabase):GetPart(id)
    assert(info, `Part not found: {id}`)

    local attachedModels: {Node3D} = {}
    local materials: {Material} = {}

    if info:IsScript(SinglePart) then
        local node = self:attachSingle(info, config)

        local list = {}
        local foundMats = searchMaterials(node, list)

        table.insert(attachedModels, node)

        for mat in foundMats do
            table.insert(materials, mat)
        end
    elseif info:IsScript(MultiPart) then
        for _, singlePartInfo: SinglePart.SinglePart in (info :: MultiPart.MultiPart).parts do
            local node = self:attachSingle(singlePartInfo, config)

            local list = {}
            local foundMats = searchMaterials(node, list)

            table.insert(attachedModels, node)

            for mat in foundMats do
                table.insert(materials, mat)
            end
        end
    end

    self.attachedParts[id] = {
        nodes = attachedModels,
        materials = materials
    }
end

function AppearanceManagerImpl.detach(self: AppearanceManager, id: string)
    if self.attachedParts[id] then
        for _, model in self.attachedParts[id].nodes do
            model:QueueFree()
        end

        self.attachedParts[id] = nil
    end
end

function AppearanceManagerImpl.loadParts(self: AppearanceManager)
    for partId: string in self.appearance.attachedParts do
        local config = self.appearance.attachedParts:Get(partId)

        if not config then
            self:attach(partId)
        else
            assert(typeof(config) == "Dictionary")
            self:attach(partId, config)
        end
    end

    for partId in self.attachedParts do
        if not self.appearance.attachedParts:Has(partId) then
            self:detach(partId)
        end
    end
end

function AppearanceManagerImpl.LoadAppearance(self: AppearanceManager)
    self:loadFace()
    self:loadParts()
    self:loadScale()
end

AppearanceManager:RegisterMethod("LoadAppearance")

function AppearanceManagerImpl._Ready(self: AppearanceManager)
    self.character = self:GetParent() :: Character.Character
    self.rig = self:GetNode("../Rig") :: Node3D
    self.skeleton = self:GetNode("../Rig/Armature/Skeleton3D") :: Skeleton3D

    self.faceMaterial = faceMaterial:Duplicate()
    self.skinMaterial = (self.skeleton:GetNode("Head") :: MeshInstance3D):GetActiveMaterial(0) :: ShaderMaterial

    local face = self.skeleton:GetNode("Face") :: MeshInstance3D
    face.materialOverride = self.faceMaterial

    self.character.cameraUpdated:Connect(Callable.new(self, "_OnCharacterCameraUpdated"))
    Callable.new(self, "LoadAppearance"):CallDeferred()
end

AppearanceManager:RegisterMethod("_Ready")

return AppearanceManager
