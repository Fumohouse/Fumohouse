local BillboardImpl = {}
local Billboard = gdclass("Billboard", "Sprite3D")
    :RegisterImpl(BillboardImpl)

type BillboardT = {
    targetPixelSize: number,

    viewport: SubViewport,
    camera: Camera3D,
    origSize: Vector2,
}

export type Billboard = Sprite3D & BillboardT & typeof(BillboardImpl)

-- In world units
Billboard:RegisterProperty("targetPixelSize", Enum.VariantType.FLOAT)
    :Range(0, 0.1)
    :Default(0.01)

function BillboardImpl.ReparentContents(self: Billboard)
	-- Hack: We cannot see the contents in editor otherwise.
	-- https://github.com/godotengine/godot/issues/39387

    local contents: Control?

    for _, child: Node in self:GetChildren() do
        if child:IsClass("Control") then
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

function BillboardImpl._Ready(self: Billboard)
    self.camera = assert(self:GetViewport():GetCamera3D())

    local viewport = SubViewport.new()
    viewport.name = "Viewport"
    viewport.disable3D = true
    viewport.transparentBg = true

    self:AddChild(viewport)

    self.texture = viewport:GetTexture()
    self.viewport = viewport

    self:ReparentContents()
end

Billboard:RegisterMethod("_Ready")

function BillboardImpl.GetScreenSize(self: Billboard): Vector2
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

    local screenTL = self.camera:UnprojectPosition(topLeft)
    local screenBR = self.camera:UnprojectPosition(bottomRight)
    local screenSize = screenBR - screenTL

    return screenSize
end

function BillboardImpl._Process(self: Billboard, delta: number)
    if self.camera:IsPositionBehind(self.globalPosition) then
        self.visible = false
        self.viewport.renderTargetUpdateMode = SubViewport.UpdateMode.DISABLED
        return
    end

    self.visible = true
    self.viewport.renderTargetUpdateMode = SubViewport.UpdateMode.ALWAYS

    -- Manual billboard helps with math
    self.globalTransform = Transform3D.new(self.camera.basis, self.globalTransform.origin)

    local screenSize = self:GetScreenSize()
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

Billboard:RegisterMethodAST("_Process")

return Billboard
