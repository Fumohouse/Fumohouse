local CameraController = require("../character/CameraController")

local WaterOverlayImpl = {}
local WaterOverlay = gdclass(nil, Control)
    :RegisterImpl(WaterOverlayImpl)

export type WaterOverlay = Control & typeof(WaterOverlayImpl) & {
    cameraPath: string,
    cameraShape: SphereShape3D?,

    camera: CameraController.CameraController,
}

WaterOverlay:RegisterProperty("cameraPath", Enum.VariantType.NODE_PATH)
    :NodePath(CameraController)

WaterOverlay:RegisterProperty("cameraShape", Enum.VariantType.OBJECT)
    :Resource(SphereShape3D)

function WaterOverlayImpl._Ready(self: WaterOverlay)
    if self.cameraPath ~= "" then
        self.camera = self:GetNode(self.cameraPath) :: CameraController.CameraController
    end
end

WaterOverlay:RegisterMethod("_Ready")

function WaterOverlayImpl._Process(self: WaterOverlay, delta: number)
    assert(self.cameraShape)

    local directSpaceState = self.camera:GetWorld3D().directSpaceState
    local cameraTransform = self.camera.globalTransform

    -- Query for intersection
    local intersectParams = PhysicsShapeQueryParameters3D.new()
    intersectParams.shape = self.cameraShape
    intersectParams.transform = cameraTransform
    intersectParams.collideWithBodies = false
    intersectParams.collideWithAreas = true

    local intersectResult = directSpaceState:IntersectShape(intersectParams)
    if intersectResult:IsEmpty() then
        self.visible = false
        return
    end

    local waterCollider: Area3D?
    for _, data: Dictionary in intersectResult do
        local collider = data:Get("collider") :: Area3D

        if collider:IsInGroup("water") then
            waterCollider = collider
            break
        end
    end

    if not waterCollider then
        self.visible = false
        return
    end

    -- Check depth with ray
    local rayParams = PhysicsRayQueryParameters3D.new()
    rayParams.from = cameraTransform.origin + Vector3.UP * self.cameraShape.radius
    rayParams.to = rayParams.from + Vector3.DOWN * (2 * self.cameraShape.radius)
    rayParams.collideWithBodies = false
    rayParams.collideWithAreas = true

    local rayResult = directSpaceState:IntersectRay(rayParams)
    if not rayResult:IsEmpty() and rayResult:Get("collider") == waterCollider then
        self.visible = false
        return
    end

    self.visible = true
end

WaterOverlay:RegisterMethodAST("_Process")

return WaterOverlay
