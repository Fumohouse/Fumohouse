--- @class RadioButtonContainer
--- @extends Control
local RadioButtonContainer = {}
local RadioButtonContainerC = gdclass(RadioButtonContainer)

--- @classType RadioButtonContainer
export type RadioButtonContainer = Control & typeof(RadioButtonContainer) & {
    --- @signal
    selectionChanged: Signal,

    --- @property
    allowNone: boolean,

    --- @property
    multiSelection: boolean,

    --- @property
    allowRemoval: boolean,

    --- @property
    --- @set SetSelection
    --- @get GetSelection
    selectedButton: Button?,

    --- @property
    --- @set SetMultipleSelection
    --- @get GetMultipleSelection
    selectedButtons: TypedArray<Button>,

    selectedButtonInternal: Button?,
    selectedButtonsInternal: TypedArray<Button>,
}

--- @registerMethod
function RadioButtonContainer.SetSelection(self: RadioButtonContainer, button: Button?)
    if self.selectedButton == button then
        return
    end

    if self.selectedButton then
        self.selectedButton.buttonPressed = false
    end

    if button then
        button.buttonPressed = true
    end

    self.selectedButtonInternal = button
    self.selectionChanged:Emit()
end

--- @registerMethod
function RadioButtonContainer.GetSelection(self: RadioButtonContainer): Button?
    return self.selectedButtonInternal
end

--- @registerMethod
function RadioButtonContainer.SetMultipleSelection(self: RadioButtonContainer, selection: TypedArray<Button>)
    for _, button: Button in self.selectedButtonsInternal do
        button.buttonPressed = false
    end

    for _, button: Button in selection do
        button.buttonPressed = true
    end

    self.selectedButtonsInternal = selection
    self.selectionChanged:Emit()
end

--- @registerMethod
function RadioButtonContainer.GetMultipleSelection(self: RadioButtonContainer): TypedArray<Button>
    return self.selectedButtonsInternal
end

--- @registerMethod
function RadioButtonContainer._OnButtonPressed(self: RadioButtonContainer, button: Button)
    if self.multiSelection then
        if self.selectedButtons:Has(button) then
            if self.selectedButtons:Size() == 1 and not self.allowNone then
                button.buttonPressed = true
                return
            end

            button.buttonPressed = false
            self.selectedButtons:Erase(button)
            self.selectionChanged:Emit()
        else
            button.buttonPressed = true
            self.selectedButtons:PushBack(button)
            self.selectionChanged:Emit()
        end
    else
        if button == self.selectedButton then
            if self.allowNone then
                self.selectedButton = nil
                self.selectionChanged:Emit()
            else
                button.buttonPressed = true
            end

            return
        end

        self.selectedButton = button
        self.selectionChanged:Emit()
    end
end

--- @registerMethod
function RadioButtonContainer._OnChildEnteredTree(self: RadioButtonContainer, child: Node)
    if not child:IsA(Button) then
        error("Non-button child is present in RadioButtonContainer.")
        return
    end

    local btn = child :: Button
    btn.toggleMode = true
    btn.buttonPressed = false
    btn.actionMode = BaseButton.ActionMode.PRESS
    btn.pressed:Connect(Callable.new(self, "_OnButtonPressed"):Bind(btn))
end

--- @registerMethod
function RadioButtonContainer._OnChildExitingTree(self: RadioButtonContainer, child: Node)
    if not self.allowRemoval or child:IsA(Button) then
        return
    end

    local btn = child :: Button
    btn.pressed:Disconnect(Callable.new(self, "_OnButtonPressed"):Bind(btn))

    if self.selectedButton then
        local idx = btn:GetIndex()

        if btn == self.selectedButton then
            self.selectedButton = if self:GetChildCount() > 0 then self:GetChild(0) :: Button else nil
        elseif idx < self.selectedButton:GetIndex() then
            self.selectedButton = self:GetChild(idx - 1) :: Button
        end

        self.selectionChanged:Emit()
    elseif self.multiSelection then
        if not self.selectedButtons:Has(btn) then
            return
        end

        self.selectedButtons:Erase(btn)
        self.selectionChanged:Emit()
    end
end

function RadioButtonContainer._Init(self: RadioButtonContainer)
    self.childEnteredTree:Connect(Callable.new(self, "_OnChildEnteredTree"))
    self.childExitingTree:Connect(Callable.new(self, "_OnChildExitingTree"))

    self.selectedButtonsInternal = Array.new()
end

return RadioButtonContainerC
