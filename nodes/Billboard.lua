--- @class Billboard
--- @extends Sprite3D
local Billboard = {}
local BillboardC = gdclass(Billboard)

export type Billboard = Sprite3D & typeof(Billboard) & {
    --- @property
    --- @range 0.001 0.1 0.01 suffix:m
    --- @default 0.01
    targetPixelSize: number,

    viewport: SubViewport,
    origSize: Vector2,
}

function Billboard.ReparentContents(self: Billboard)
	-- Hack: We cannot see the contents in editor otherwise.
	-- https://github.com/godotengine/godot/issues/39387

    local contents: Control?

    for _, child: Node in self:GetChildren() do
        if child:IsA(Control) then
            contents = child :: Control
            break
        end
    end

    if not contents then
        error("Billboard must have a Control child in order to function.")
    else
        self.origSize = contents.size

        contents:Reparent(self.viewport)

        -- Visible is false in editor to not clutter 2D view. Again a hack.
        contents.visible = true
    end
end

--- @registerMethod
function Billboard._Ready(self: Billboard)
    local viewport = SubViewport.new()
    viewport.name = "Viewport"
    viewport.disable3D = true
    viewport.transparentBg = true

    self:AddChild(viewport)

    self.texture = viewport:GetTexture()
    self.viewport = viewport

    self:ReparentContents()
end

function Billboard.getCorners(self: Billboard)
    local gBasis = self.globalTransform.basis

    local worldSize = self.origSize * self.targetPixelSize
    local worldOffset = self.offset * self.targetPixelSize
    local worldOrigin = self.globalPosition
        + gBasis.x * worldOffset.x
        + gBasis.y * worldOffset.y

    local topLeft = worldOrigin
        - gBasis.x * worldSize.x / 2
        + gBasis.y * worldSize.y / 2

    local bottomRight = worldOrigin
        + gBasis.x * worldSize.x / 2
        - gBasis.y * worldSize.y / 2

    return topLeft, bottomRight
end

function Billboard.GetScreenSize(self: Billboard, camera: Camera3D)
    local topLeft, bottomRight = self:getCorners()

    local screenTL = camera:UnprojectPosition(topLeft)
    local screenBR = camera:UnprojectPosition(bottomRight)
    local screenSize = screenBR - screenTL

    return screenSize
end

--- @registerMethod
function Billboard._Process(self: Billboard, delta: number)
    if not self.visible then
        return
    end

    local camera = self:GetViewport():GetCamera3D()
    if not camera then
        return
    end

    if camera:IsPositionBehind(self.globalPosition) then
        self.viewport.renderTargetUpdateMode = SubViewport.UpdateMode.DISABLED
        return
    end

    self.viewport.renderTargetUpdateMode = SubViewport.UpdateMode.ALWAYS

    -- Manual billboard helps with math
    self.globalTransform = Transform3D.new(camera.basis, self.globalTransform.origin)

    local screenSize = self:GetScreenSize(camera)
    local maxSize = self:GetWindow().size * 4

    local viewportSize: Vector2
    if screenSize.x > maxSize.x or screenSize.y > maxSize.y then
        local width = maxSize.x
        local height = maxSize.x * self.origSize.y / self.origSize.x

        viewportSize = Vector2.new(width, height)
    else
        viewportSize = screenSize
    end

    -- I don't really know how this works.
    -- This basically replicates Godot's canvas_items scaling mode.
    -- Reference: window.cpp
    self.viewport.size = Vector2i.new(viewportSize)
    self.viewport.size2DOverride = Vector2i.new(self.origSize)
    self.viewport.canvasTransform = Transform2D.IDENTITY:Scaled(viewportSize / self.origSize)

    -- Must adjust the pixel size in order to update texture size, etc.
    self.pixelSize = self.targetPixelSize * self.origSize.x / screenSize.x
end

--- @registerMethod
function Billboard._UnhandledInput(self: Billboard, event: InputEvent)
    local camera = self:GetViewport():GetCamera3D()
    if not camera then
        return
    end

    if not event:IsA(InputEventMouse) then
        return
    end

    local em = event :: InputEventMouse

    local plane = Plane.new(self.globalBasis.z, self.globalPosition)
    local cameraRayOrig = camera:ProjectRayOrigin(em.position)
    local cameraRayNorm = camera:ProjectRayNormal(em.position)

    local intersect = plane:IntersectsRay(cameraRayOrig, cameraRayNorm) :: Vector3?
    if not intersect then
        return
    end

    local topLeft = self:getCorners()
    local screenSize = self:GetScreenSize(camera)

    local offset = intersect - topLeft

    local x = offset:Dot(self.globalBasis.x)
    local y = -offset:Dot(self.globalBasis.y)

    if x < 0 or y < 0 or x > screenSize.x or y > screenSize.y then
        return
    end

    local viewportPos = Vector2.new(x, y) / self.pixelSize

    local viewportEvt = em:Duplicate()
    viewportEvt.position = viewportPos

    self.viewport:PushInput(viewportEvt, true)
end

return BillboardC
