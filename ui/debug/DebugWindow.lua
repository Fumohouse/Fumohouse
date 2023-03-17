local DebugWindowImpl = {}
local DebugWindow = gdclass(nil, Control)
    :RegisterImpl(DebugWindowImpl)

export type DebugWindowT = {
    topBar: Control,
    contents: Control,
    resizeHandle: Control,

    action: string,

    isDragging: boolean,
    isResizing: boolean,

    customSize: Vector2,
}

export type DebugWindow = Control & DebugWindowT & typeof(DebugWindowImpl)

function DebugWindowImpl._Init(obj: Control, tbl: DebugWindowT)
    tbl.action = ""
    tbl.isDragging = false
    tbl.isResizing = false
end

function DebugWindowImpl._Ready(self: DebugWindow)
    self.customSize = self:GetMinimumSize()

    self.topBar = self:GetNode("%TopBar") :: Control
    self.topBar.guiInput:Connect(Callable.new(self, "_OnTopBarGuiInput"))

    self.contents = self:GetNode("%Contents") :: Control

    self.resizeHandle = self:GetNode("%ResizeHandle") :: Control
    self.resizeHandle.guiInput:Connect(Callable.new(self, "_OnResizeHandleGuiInput"))

    local closeButton = self:GetNode("%CloseButton") :: Button
    closeButton.pressed:Connect(Callable.new(self, "SetVisible"):Bind(false))
end

DebugWindow:RegisterMethod("_Ready")

function DebugWindowImpl.SetContentsVisible(self: DebugWindow, visible: boolean)
    self.contents.visible = visible
    self.resizeHandle.visible = visible
end

function DebugWindowImpl.SetWindowVisible(self: DebugWindow, visible: boolean)
    self.visible = visible
    self:SetProcess(visible)
end

function DebugWindowImpl.updateLayout(self: DebugWindow, newPosition: Vector2?, newSize: Vector2?)
    local viewportRect = self:GetViewportRect()

    -- Setting minimum size is no longer automatic after layout change
    if self.contents.visible then
        local targetSize = newSize or self.customSize
        self.size = targetSize:Clamp(self:GetMinimumSize(), viewportRect.size - self.position)
        self.customSize = self.size
    else
        self.size = self:GetMinimumSize()
    end

    -- Keep position within viewport
    local targetPos = (newPosition or self.position):Clamp(
        Vector2.ZERO,
        Vector2.new(viewportRect.size.x - self.size.x, viewportRect.size.y - self.size.y)
    )

    self.position = targetPos
end

function DebugWindowImpl._GuiInput(self: DebugWindow, event: InputEvent)
    if event:IsA(InputEventMouseButton) then
        local emb = event :: InputEventMouseButton
        if emb.pressed then
            self:MoveToFront()
        end
    end
end

DebugWindow:RegisterMethodAST("_GuiInput")

function DebugWindowImpl._OnTopBarGuiInput(self: DebugWindow, event: InputEvent)
    if event:IsA(InputEventMouseButton) then
        local emb = event :: InputEventMouseButton

        if emb.doubleClick then
            self:SetContentsVisible(not self.contents.visible)
            self:updateLayout()
        else
            self.isDragging = emb.pressed
        end

        self.topBar:AcceptEvent()
    elseif event:IsA(InputEventMouseMotion) then
        if not self.isDragging then
            return
        end

        local emm = event :: InputEventMouseMotion
        self:updateLayout(self.position + emm.relative)

        self.topBar:AcceptEvent()
    end
end

DebugWindow:RegisterMethodAST("_OnTopBarGuiInput")

function DebugWindowImpl._OnResizeHandleGuiInput(self: DebugWindow, event: InputEvent)
    if event:IsA(InputEventMouseButton) then
        local emb = event :: InputEventMouseButton

        self.isResizing = emb.pressed
        self.resizeHandle:AcceptEvent()
    elseif event:IsA(InputEventMouseMotion) then
        if not self.isResizing then
            return
        end

        local emm = event :: InputEventMouseMotion
        self:updateLayout(nil, self.size + emm.relative)

        self.resizeHandle:AcceptEvent()
    end
end

DebugWindow:RegisterMethodAST("_OnResizeHandleGuiInput")

function DebugWindowImpl._UnhandledInput(self: DebugWindow, event: InputEvent)
    if self.action ~= "" and event:IsActionPressed(self.action) then
        self:SetWindowVisible(not self.visible)
    end
end

DebugWindow:RegisterMethodAST("_UnhandledInput")

return DebugWindow
