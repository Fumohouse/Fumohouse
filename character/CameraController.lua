local Utils = require("../utils/Utils.mod")

local CameraControllerImpl = {}
local CameraController = gdclass("CameraController", Camera3D)
    :RegisterImpl(CameraControllerImpl)

type CameraControllerT = {
    cameraOffset: number,
    cameraZoomSens: number,
    cameraRotateSens: number,
    maxFocusDistance: number,
    focusDistanceTarget: number,

    focusNode: Node3D?,
    cameraRotation: Vector2,
    focusDistance: number,
    lastMousePos: Vector2,
    cameraRotating: boolean,
    cameraMode: number
}

export type CameraController = Camera3D & CameraControllerT & typeof(CameraControllerImpl)

CameraControllerImpl.CameraMode = {
    -- Focused, no zoom
    FIRST_PERSON = 0,

    -- Focused, zoomed out
    THIRD_PERSON = 1,

    -- No focus
    FLOATING = 2,
}

local CAMERA_MAX_X_ROT = math.pi / 2 - 1e-2

CameraController:RegisterProperty("cameraOffset", Enum.VariantType.FLOAT)
    :Range(0, 10)
    :Default(2.5)

CameraController:RegisterProperty("cameraZoomSens", Enum.VariantType.FLOAT)
    :Range(0, 5)
    :Default(1)

CameraController:RegisterProperty("cameraRotateSens", Enum.VariantType.FLOAT)
    :Range(0, 3)
    :Default(math.pi / 200)

CameraController:RegisterProperty("maxFocusDistance", Enum.VariantType.FLOAT)
    :Range(0, 200)
    :Default(50)

CameraController:RegisterProperty("focusDistanceTarget", Enum.VariantType.FLOAT)
    :Range(0, 200)
    :Default(5)

function CameraControllerImpl._Init(obj: Camera3D, tbl: CameraControllerT)
    tbl.cameraRotation = Vector2.ZERO
    tbl.focusDistance = tbl.focusDistanceTarget
    tbl.lastMousePos = Vector2.ZERO
    tbl.cameraRotating = false
    tbl.cameraMode = CameraController.CameraMode.FLOATING
end

function CameraControllerImpl.GetFocalPoint(self: CameraController)
    assert(self.focusNode)
    return self.focusNode.globalPosition + self.focusNode.globalTransform.basis.y * self.cameraOffset
end

function CameraControllerImpl.processFirstPerson(self: CameraController)
    if self.focusNode then
        self.globalTransform = Transform3D.new(
            self.focusNode.globalTransform.basis:Orthonormalized(),
            self:GetFocalPoint()
        )
    end

    self.rotation = Vector3.new(
        self.cameraRotation.x,
        self.cameraRotation.y,
        self.rotation.z
    )
end

function CameraControllerImpl.processThirdPerson(self: CameraController)
    local focalPoint = self:GetFocalPoint()
    local camBasis = Basis.IDENTITY
        :Rotated(Vector3.RIGHT, self.cameraRotation.x)
        :Rotated(Vector3.UP, self.cameraRotation.y)

    local pos = focalPoint + camBasis * Vector3.new(0, 0, self.focusDistance)

    local parameters = PhysicsRayQueryParameters3D.new()
    parameters.from = focalPoint
    parameters.to = pos

    local result = self:GetWorld3D().directSpaceState:IntersectRay(parameters)
    if result:Has("position") then
        pos = (result:Get("position") :: Vector3) * 0.99
    end

    self.globalTransform = Transform3D.new(Basis.IDENTITY, pos)
        :LookingAt(focalPoint, Vector3.UP)
end

function CameraControllerImpl.setCameraRotating(self: CameraController, rotating: boolean)
    if self.cameraRotating == rotating then
        return
    end

    if rotating then
        self.lastMousePos = self:GetViewport():GetMousePosition()
        Input.GetSingleton().mouseMode = Input.MouseMode.CAPTURED
    else
        Input.GetSingleton().mouseMode = Input.MouseMode.VISIBLE
        self:GetViewport():WarpMouse(self.lastMousePos)
    end

    self.cameraRotating = rotating
end

function CameraControllerImpl._Process(self: CameraController, delta: number)
    if not self.current then
        return
    end

    -- "Tween" camera focal distance
    if self.cameraMode ~= CameraController.CameraMode.FLOATING then
        if math.abs(self.focusDistanceTarget - self.focusDistance) >= 1e-2 then
            self.focusDistance = lerp(self.focusDistance, self.focusDistanceTarget, Utils.LerpWeight(delta))
        else
            self.focusDistance = self.focusDistanceTarget
        end
    end

    if not self.focusNode then
        self.cameraMode = CameraController.CameraMode.FLOATING
    elseif self.focusDistanceTarget == 0 then
        self.cameraMode = CameraController.CameraMode.FIRST_PERSON
        self:setCameraRotating(true)
    else
        if self.cameraMode == CameraController.CameraMode.FIRST_PERSON then
            self:setCameraRotating(false)
        end

        self.cameraMode = CameraController.CameraMode.THIRD_PERSON
    end

    if not self.focusNode or self.focusDistance == 0.0 then
        self:processFirstPerson()
    else
        self:processThirdPerson()
    end
end

CameraController:RegisterMethodAST("_Process")

function CameraControllerImpl._UnhandledInput(self: CameraController, event: InputEvent)
    -- Zoom
    if self.focusNode then
        if event:IsActionPressed("camera_zoom_in") then
            self.focusDistanceTarget = math.max(self.focusDistanceTarget - self.cameraZoomSens, 0)
        elseif event:IsActionPressed("camera_zoom_out") then
            self.focusDistanceTarget = math.min(self.focusDistanceTarget + self.cameraZoomSens, self.maxFocusDistance)
        end
    end

    -- Rotate
    if typeof(event) == "InputEventMouseMotion" and self.cameraRotating then
        local relative = (event :: InputEventMouseMotion).relative
        local rotDelta = relative * self.cameraRotateSens
        if self.cameraMode ~= CameraController.CameraMode.THIRD_PERSON then
            rotDelta *= 0.25
        end

        self.cameraRotation = Vector2.new(
            math.clamp(self.cameraRotation.x - rotDelta.y, -CAMERA_MAX_X_ROT, CAMERA_MAX_X_ROT),
            (self.cameraRotation.y - rotDelta.x) % (2 * math.pi)
        )
    end

    -- Trigger rotate
    if self.cameraMode ~= CameraController.CameraMode.FIRST_PERSON and event:IsAction("camera_rotate") then
        self:setCameraRotating(event:IsActionPressed("camera_rotate"))
    end
end

CameraController:RegisterMethodAST("_UnhandledInput")

return CameraController
