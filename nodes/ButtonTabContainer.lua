local ButtonTabContainerImpl = {}
local ButtonTabContainer = gdclass("ButtonTabContainer", HBoxContainer)
    :RegisterImpl(ButtonTabContainerImpl)

export type ButtonTabContainer = HBoxContainer & typeof(ButtonTabContainerImpl) & {
    selectionChanged: Signal,
    -- Following Godot convention (rather than Lua), this value is 0 indexed.
    selection: number,

    selectedButton: Button?,
    selectionInternal: number,
}

ButtonTabContainer:RegisterSignal("selectionChanged")
ButtonTabContainer:RegisterProperty("selection", Enum.VariantType.INT)
    :SetGet("SetSelection", "GetSelection")

function ButtonTabContainerImpl.SetSelection(self: ButtonTabContainer, value: number)
    if self.selection == value then
        return
    end

    -- Allow negative value for no selection
    assert(value < self:GetChildCount(), "Value is out of bounds.")

    if self.selectedButton then
        self.selectedButton.buttonPressed = false
    end

    if value >= 0 then
        local btn = assert(self:GetChild(value)) :: Button
        btn.buttonPressed = true
        self.selectedButton = btn
    else
        self.selectedButton = nil
    end

    self.selectionInternal = value
    self.selectionChanged:Emit()
end

ButtonTabContainer:RegisterMethodAST("SetSelection")

function ButtonTabContainerImpl.GetSelection(self: ButtonTabContainer): number
    return self.selectionInternal
end

ButtonTabContainer:RegisterMethodAST("GetSelection")

function ButtonTabContainerImpl._OnButtonPressed(self: ButtonTabContainer, button: Button)
    if button == self.selectedButton then
        button.buttonPressed = true
        return
    end

    self.selection = button:GetIndex()
end

ButtonTabContainer:RegisterMethodAST("_OnButtonPressed")

function ButtonTabContainerImpl._OnChildEnteredTree(self: ButtonTabContainer, child: Node)
    if not child:IsA(Button) then
        error("Non-button child is present in ButtonTabContainer.")
        return
    end

    local btn = child :: Button
    btn.toggleMode = true
    btn.actionMode = BaseButton.ActionMode.PRESS
    btn.pressed:Connect(Callable.new(self, "_OnButtonPressed"):Bind(btn))
end

ButtonTabContainer:RegisterMethodAST("_OnChildEnteredTree")

function ButtonTabContainerImpl._OnChildExitingTree(self: ButtonTabContainer, child: Node)
    if not child:IsA(Button) then
        return
    end

    local btn = child :: Button
    btn.pressed:Disconnect(Callable.new(self, "_OnButtonPressed"):Bind(btn))

    local idx = btn:GetIndex()

    print(idx)
    if idx == self.selection then
        self.selection = 0
    elseif idx < self.selection then
        self.selection -= 1
    end
end

ButtonTabContainer:RegisterMethodAST("_OnChildExitingTree")

function ButtonTabContainerImpl._Init(self: ButtonTabContainer)
    self.selectionInternal = -1

    self.childEnteredTree:Connect(Callable.new(self, "_OnChildEnteredTree"))
    self.childExitingTree:Connect(Callable.new(self, "_OnChildExitingTree"))
end

return ButtonTabContainer
