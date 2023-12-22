local Appearance = require("Appearance")
local Character = require("../Character")
local CameraController = require("../CameraController")
local SinglePart = require("parts/SinglePart")
local MultiPart = require("parts/MultiPart")
local FaceDatabase = require("face/FaceDatabase")
local FacePartStyle = require("face/FacePartStyle")
local EyeStyle = require("face/EyeStyle")
local PartCustomizer = require("parts/customization/PartCustomizer")
local Utils = require("../../utils/Utils.mod")

local PartDatabaseM = require("parts/PartDatabase")
local PartDatabase = gdglobal("PartDatabase") :: PartDatabaseM.PartDatabase

--- @class
--- @extends Node3D
local AppearanceManager = {}
local AppearanceManagerC = gdclass(AppearanceManager)

type AttachedPartInfo = {
    nodes: {Node3D},
    materials: {Material},
}

--- @classType AppearanceManager
export type AppearanceManager = Node3D & typeof(AppearanceManager) & {
    --- @property
    character: Character.Character,
    --- @property
    rig: Node3D,
    --- @property
    skeleton: Skeleton3D,
    --- @property
    nametag: Sprite3D,

    --- @property
    appearance: Appearance.Appearance,

    --- @property
    --- @default 1.5
    cameraFadeBegin: number,

    --- @property
    --- @default 0.25
    cameraFadeEnd: number,

    --- @property
    --- @default 0.5
    nametagOffset: number,

    faceMaterial: ShaderMaterial,
    skinMaterial: ShaderMaterial,

    attachedParts: {[string]: AttachedPartInfo},
    baseRagdollColliderPosition: Vector3,
    baseCameraOffset: number,

    alpha: number,
    dissolve: number,
}

AppearanceManager.ATTACHMENTS = {
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

local faceMaterial: ShaderMaterial = assert(load("face/face_material.tres"))
local faceDatabase: FaceDatabase.FaceDatabase = assert(load("res://resources/face_database.tres"))

function AppearanceManager._Init(self: AppearanceManager)
    self.attachedParts = {}
    self.baseCameraOffset = 0

    self.alpha = 1
    self.dissolve = 0
end

function AppearanceManager.setShaderParameter(self: AppearanceManager, param: string, value: Variant)
    self.faceMaterial:SetShaderParameter(param, value)
    self.skinMaterial:SetShaderParameter(param, value)

    for _, info in self.attachedParts do
        for _, material in info.materials do
            if not material:IsA(ShaderMaterial) then
                continue
            end

            local shaderMaterial = material :: ShaderMaterial
            if not shaderMaterial:GetShaderParameter(param) then
                continue
            end

            shaderMaterial:SetShaderParameter(param, value)
        end
    end
end

function AppearanceManager.setAlpha(self: AppearanceManager, alpha: number, force: boolean?)
    if self.alpha == alpha and not force then
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

    self:setShaderParameter("alpha", alpha)
end

--- @registerMethod
--- @defaultArgs [false]
function AppearanceManager.SetDissolve(self: AppearanceManager, dissolve: number, force: boolean?)
    if self.dissolve == dissolve and not force then
        return
    end

    self.dissolve = dissolve
    self:setShaderParameter("dissolve", dissolve)
end

function AppearanceManager.loadScale(self: AppearanceManager)
    local scaleVec = Vector3.ONE * self.appearance.scale

    self.rig.scale = scaleVec
    self.rig.position = Vector3.ZERO

    local mainCollider = self.character.state.mainCollider
    mainCollider.scale = scaleVec
    mainCollider.position = Vector3.UP * self.character.state.mainCollisionShape.height * self.appearance.scale / 2

    local ragdollCollider = self.character.state.ragdollCollider
    ragdollCollider.scale = scaleVec
    ragdollCollider.position = self.baseRagdollColliderPosition * self.appearance.scale

    if self.character.camera then
        self.character.camera.cameraOffset = self.baseCameraOffset * self.appearance.scale
    end
end

function AppearanceManager.updateAlphaCamera(self: AppearanceManager)
    if not self.character.camera then
        return
    end

    if self.character.camera.cameraMode == CameraController.CameraMode.FIRST_PERSON then
        self:setAlpha(0)
        return
    end

    local distance = (
        self.character.camera.globalPosition - self.character.camera:GetFocalPoint()
    ):Length()

    local beginScaled = self.cameraFadeBegin * self.appearance.scale
    local endScaled = self.cameraFadeEnd * self.appearance.scale

    local alpha = (distance - endScaled) / (beginScaled - endScaled)
    alpha = math.clamp(alpha, 0, 1)

    self:setAlpha(alpha)
end

function AppearanceManager.updateNametagPosition(self: AppearanceManager)
    if not self.nametag.visible then
        return
    end

    local headAtt = self:GetNode("Head") :: Node3D

    local aabb = self.globalTransform * Utils.CalculateBounds(headAtt)
    local topY = aabb["end"].y + self.nametagOffset * self.appearance.scale

    self.nametag.globalPosition = Vector3.new(headAtt.globalPosition.x, topY, headAtt.globalPosition.z)
end

--- @registerMethod
function AppearanceManager._Process(self: AppearanceManager, delta: number)
    self:updateAlphaCamera()
    self:updateNametagPosition()
end

--- @registerMethod
function AppearanceManager._OnCharacterCameraUpdated(self: AppearanceManager, camera: CameraController.CameraController)
    self.baseCameraOffset = camera.cameraOffset
    self:loadScale()
end

function AppearanceManager.loadFacePartStyle(self: AppearanceManager, getCb, styleName: string, uniform: string)
    local texture: Texture2D?

    if styleName ~= "" then
        local style: FacePartStyle.FacePartStyle? = getCb(faceDatabase, styleName)
        assert(style, `Failed to load face style: {styleName}`)

        texture = style.texture
    end

    self.faceMaterial:SetShaderParameter(uniform, texture)
end

function AppearanceManager.loadFace(self: AppearanceManager)
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

    self.faceMaterial:SetShaderParameter("eye_texture", eyeTexture)
    self.faceMaterial:SetShaderParameter("shine_texture", shineTexture)
    self.faceMaterial:SetShaderParameter("overlay_texture", overlayTexture)
end

function AppearanceManager.attachSingle(self: AppearanceManager, partInfo: SinglePart.SinglePart)
    local node = (assert(load(SinglePart.BASE_PATH .. partInfo.scenePath)) :: PackedScene):Instantiate() :: Node3D

    local targetAtt = self:GetNode(AppearanceManager.ATTACHMENTS[partInfo.bone]) :: BoneAttachment3D
    targetAtt:AddChild(node)
    node.transform = partInfo.transform

    return node
end

local function searchMaterials(node: Node3D, list: {[Material]: true})
    if node:IsA(MeshInstance3D) then
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
        if child:IsA(Node3D) then
            searchMaterials(child :: Node3D, list)
        end
    end

    return list
end

function AppearanceManager.attach(self: AppearanceManager, id: string)
    if self.attachedParts[id] then
        return
    end

    local info = PartDatabase:GetPart(id)
    assert(info, `Part not found: {id}`)

    local attachedModels: {Node3D} = {}
    local materials: {Material} = {}

    if info:IsA(SinglePart) then
        local node = self:attachSingle(info)

        local list = {}
        local foundMats = searchMaterials(node, list)

        table.insert(attachedModels, node)

        for mat in foundMats do
            table.insert(materials, mat)
        end
    elseif info:IsA(MultiPart) then
        for _, singlePartInfo: SinglePart.SinglePart in (info :: MultiPart.MultiPart).parts do
            local node = self:attachSingle(singlePartInfo)

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

function AppearanceManager.detach(self: AppearanceManager, id: string)
    if not self.attachedParts[id] then
        return
    end

    for _, model in self.attachedParts[id].nodes do
        model:QueueFree()
    end

    self.attachedParts[id] = nil
end

function AppearanceManager.loadParts(self: AppearanceManager)
    for partId: string in self.appearance.attachedParts do
        self:attach(partId)
    end

    for partId, attInfo in self.attachedParts do
        if self.appearance.attachedParts:Has(partId) then
            local config = self.appearance.attachedParts:Get(partId)
            assert(typeof(config) == "nil" or typeof(config) == "Dictionary")

            for _, node in attInfo.nodes do
                if node:IsA(PartCustomizer) then
                    (node :: PartCustomizer.PartCustomizer):Update(self.appearance, config)
                end
            end
        else
            self:detach(partId)
        end
    end
end

--- @registerMethod
function AppearanceManager.LoadAppearance(self: AppearanceManager)
    self:loadFace()
    self:loadParts()
    self:loadScale()

    self:setAlpha(self.alpha, true)
    self:SetDissolve(self.dissolve, true)
end

--- @registerMethod
function AppearanceManager._Ready(self: AppearanceManager)
    self.faceMaterial = faceMaterial:Duplicate()
    self.skinMaterial = (self.skeleton:GetNode("Head") :: MeshInstance3D):GetActiveMaterial(0) :: ShaderMaterial

    local head = self.skeleton:GetNode("Head") :: MeshInstance3D
    head.materialOverride = self.faceMaterial

    self.baseRagdollColliderPosition = (self:GetNode("../RagdollCollider") :: CollisionShape3D).position

    self.character.cameraUpdated:Connect(Callable.new(self, "_OnCharacterCameraUpdated"))
    Callable.new(self, "LoadAppearance"):CallDeferred()
end

return AppearanceManagerC
