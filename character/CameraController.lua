local Utils = require("../utils/Utils.mod")

local ConfigManagerM = require("../config/ConfigManager")
local ConfigManager = gdglobal("ConfigManager") :: ConfigManagerM.ConfigManager

--- @class CameraController
--- @extends Camera3D
local CameraController = {}
local CameraControllerC = gdclass(CameraController)

--- @classType CameraController
export type CameraController = Camera3D & typeof(CameraController) & {
    --- @property
    --- @range 0 10
    --- @default 2.5
    cameraOffset: number,

    --- @property
    --- @range 0 200
    --- @default 50.0
    maxFocusDistance: number,

    --- @property
    --- @range 0 200
    --- @default 5.0
    focusDistanceTarget: number,

    --- @signal
    modeChanged: SignalWithArgs<(mode: integer) -> ()>,

    cameraZoomSens: number,
    cameraLookSensFirstPerson: number,
    cameraLookSensThirdPerson: number,

    focusNode: Node3D?,
    cameraRotation: Vector2,
    focusDistance: number,
    lastMousePos: Vector2,
    cameraRotating: boolean,
    cameraMode: number
}

CameraController.CameraMode = {
    -- Focused, no zoom
    FIRST_PERSON = 0,

    -- Focused, zoomed out
    THIRD_PERSON = 1,

    -- No focus
    FLOATING = 2,
}

local CAMERA_MAX_X_ROT = math.pi / 2 - 1e-2

function CameraController._Init(self: CameraController)
    self.cameraRotation = Vector2.ZERO
    self.focusDistance = self.focusDistanceTarget
    self.lastMousePos = Vector2.ZERO
    self.cameraRotating = false
    self.cameraMode = -1
end

function CameraController.GetFocalPoint(self: CameraController)
    assert(self.focusNode)
    return self.focusNode.globalPosition + self.focusNode.globalTransform.basis.y * self.cameraOffset
end

function CameraController.processFirstPerson(self: CameraController)
    if self.focusNode then
        self.globalTransform = Transform3D.new(
            Basis.IDENTITY,
            self:GetFocalPoint()
        )
    end

    self.rotation = Vector3.new(
        self.cameraRotation.x,
        self.cameraRotation.y,
        self.rotation.z
    )
end

function CameraController.processThirdPerson(self: CameraController)
    local focalPoint = self:GetFocalPoint()
    local camBasis = Basis.IDENTITY
        :Rotated(Vector3.RIGHT, self.cameraRotation.x)
        :Rotated(Vector3.UP, self.cameraRotation.y)

    local pos = focalPoint + camBasis * Vector3.new(0, 0, self.focusDistance)

    local parameters = PhysicsRayQueryParameters3D.new()
    parameters.from = focalPoint
    parameters.to = pos

    local result = self:GetWorld3D().directSpaceState:IntersectRay(parameters)
    if not result:IsEmpty() then
        pos = (result:Get("position") :: Vector3) * 0.99
    end

    self.globalTransform = Transform3D.new(Basis.IDENTITY, pos)
        :LookingAt(focalPoint, Vector3.UP)
end

function CameraController.setCameraRotating(self: CameraController, rotating: boolean)
    if self.cameraRotating == rotating then
        return
    end

    if rotating then
        self.lastMousePos = self:GetViewport():GetMousePosition()
        Input.singleton.mouseMode = Input.MouseMode.CAPTURED
    else
        Input.singleton.mouseMode = Input.MouseMode.VISIBLE
        self:GetViewport():WarpMouse(self.lastMousePos)
    end

    self.cameraRotating = rotating
end

--- @registerMethod
function CameraController.HandlePopup(self: CameraController)
    if self.cameraMode == CameraController.CameraMode.THIRD_PERSON then
        self:setCameraRotating(false)
    end
end

function CameraController.applyFov(self: CameraController)
    self.fov = ConfigManager:Get("graphics/fov") :: number
end

function CameraController.applySensFirstPerson(self: CameraController)
    self.cameraLookSensFirstPerson = math.rad(ConfigManager:Get("input/sens/camera/firstPerson") :: number)
end

function CameraController.applySensThirdPerson(self: CameraController)
    self.cameraLookSensThirdPerson = math.rad(ConfigManager:Get("input/sens/camera/thirdPerson") :: number)
end

function CameraController.applyZoomSens(self: CameraController)
    self.cameraZoomSens = ConfigManager:Get("input/sens/cameraZoom") :: number
end

--- @registerMethod
function CameraController._OnConfigValueChanged(self: CameraController, key: string)
    if key == "graphics/fov" then
        self:applyFov()
    elseif key == "input/sens/camera/firstPerson" then
        self:applySensFirstPerson()
    elseif key == "input/sens/camera/thirdPerson" then
        self:applySensThirdPerson()
    elseif key == "input/sens/cameraZoom" then
        self:applyZoomSens()
    end
end

--- @registerMethod
function CameraController._Ready(self: CameraController)
    self:applyFov()
    self:applySensFirstPerson()
    self:applySensThirdPerson()
    self:applyZoomSens()
    ConfigManager.valueChanged:Connect(Callable.new(self, "_OnConfigValueChanged"))
end

--- @registerMethod
function CameraController._Process(self: CameraController, delta: number)
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

    local oldMode = self.cameraMode

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

    if oldMode ~= self.cameraMode then
        self.modeChanged:Emit(self.cameraMode)
    end

    if not self.focusNode or self.focusDistance == 0.0 then
        self:processFirstPerson()
    else
        self:processThirdPerson()
    end
end

--- @registerMethod
function CameraController._UnhandledInput(self: CameraController, event: InputEvent)
    if not Utils.DoGameInput(self) then
        return
    end

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
        local rotDelta = relative * if self.cameraMode == CameraController.CameraMode.FIRST_PERSON then
            self.cameraLookSensFirstPerson
        else
            self.cameraLookSensThirdPerson

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

return CameraControllerC
