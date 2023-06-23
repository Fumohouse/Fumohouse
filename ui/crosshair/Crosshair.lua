local CameraController = require("../../character/CameraController")

--- @class
--- @extends Control
local Crosshair = {}
local CrosshairC = gdclass(Crosshair)

--- @classType Crosshair
export type Crosshair = Control & typeof(Crosshair)

--- @registerMethod
function Crosshair.UpdateCameraMode(self: Crosshair, mode: integer)
    self.visible = mode == CameraController.CameraMode.FIRST_PERSON
end

return CrosshairC
