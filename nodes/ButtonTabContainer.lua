--- @class ButtonTabContainer
--- @extends HBoxContainer
local ButtonTabContainer = {}
local ButtonTabContainerC = gdclass(ButtonTabContainer)

--- @classType ButtonTabContainer
export type ButtonTabContainer = HBoxContainer & typeof(ButtonTabContainer) & {
    --- @signal
    selectionChanged: Signal,

    --- Following Godot convention (rather than Lua), this value is 0 indexed.
    --- @property
    --- @set SetSelection
    --- @get GetSelection
    selection: integer,

    selectedButton: Button?,
    selectionInternal: number,
}

--- @registerMethod
function ButtonTabContainer.SetSelection(self: ButtonTabContainer, value: number)
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

--- @registerMethod
function ButtonTabContainer.GetSelection(self: ButtonTabContainer): number
    return self.selectionInternal
end

--- @registerMethod
function ButtonTabContainer._OnButtonPressed(self: ButtonTabContainer, button: Button)
    if button == self.selectedButton then
        button.buttonPressed = true
        return
    end

    self.selection = button:GetIndex()
end

--- @registerMethod
function ButtonTabContainer._OnChildEnteredTree(self: ButtonTabContainer, child: Node)
    if not child:IsA(Button) then
        error("Non-button child is present in ButtonTabContainer.")
        return
    end

    local btn = child :: Button
    btn.toggleMode = true
    btn.actionMode = BaseButton.ActionMode.PRESS
    btn.pressed:Connect(Callable.new(self, "_OnButtonPressed"):Bind(btn))
end

--- @registerMethod
function ButtonTabContainer._OnChildExitingTree(self: ButtonTabContainer, child: Node)
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

function ButtonTabContainer._Init(self: ButtonTabContainer)
    self.selectionInternal = -1

    self.childEnteredTree:Connect(Callable.new(self, "_OnChildEnteredTree"))
    self.childExitingTree:Connect(Callable.new(self, "_OnChildExitingTree"))
end

return ButtonTabContainerC
