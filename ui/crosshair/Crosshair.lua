local CameraController = require("../../character/CameraController")

local CrosshairImpl = {}
local Crosshair = gdclass(nil, Control)
    :RegisterImpl(CrosshairImpl)

export type Crosshair = Control & typeof(CrosshairImpl)

function CrosshairImpl.UpdateCameraMode(self: Crosshair, mode: integer)
    self.visible = mode == CameraController.CameraMode.FIRST_PERSON
end

Crosshair:RegisterMethodAST("UpdateCameraMode")

return Crosshair
