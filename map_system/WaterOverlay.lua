local CameraController = require("../character/CameraController")

--- @class
--- @extends Control
local WaterOverlay = {}
local WaterOverlayC = gdclass(WaterOverlay)

--- @classType WaterOverlay
export type WaterOverlay = Control & typeof(WaterOverlay) & {
    --- @property
    cameraPath: NodePathConstrained<CameraController.CameraController>,
    --- @property
    cameraShape: SphereShape3D?,

    camera: CameraController.CameraController,
}

--- @registerMethod
function WaterOverlay._Ready(self: WaterOverlay)
    if self.cameraPath ~= "" then
        self.camera = self:GetNode(self.cameraPath) :: CameraController.CameraController
    end
end

--- @registerMethod
function WaterOverlay._Process(self: WaterOverlay, delta: number)
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

return WaterOverlayC
