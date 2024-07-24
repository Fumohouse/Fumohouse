local RadioButtonContainer = require("../../nodes/RadioButtonContainer")
local TransitionElement = require("TransitionElement")

--- @class
--- @extends TransitionElement
local ScreenBase = {}
local ScreenBaseC = gdclass(ScreenBase)

export type ScreenBase = TransitionElement.TransitionElement & typeof(ScreenBase) & {
    --- @property
    tabContainer: RadioButtonContainer.RadioButtonContainer?,
    --- @property
    tabs: Control?,

    currentTab: Control?,
}

--- @registerMethod
function ScreenBase._Ready(self: ScreenBase)
    if self.tabContainer and self.tabs then
        for _, child: Control in self.tabs:GetChildren() do
            child.visible = false
        end

        self.tabContainer.selectedButton = self.tabContainer:GetChild(0) :: Button
        self:_OnSelectionChanged()
        self.tabContainer.selectionChanged:Connect(Callable.new(self, "_OnSelectionChanged"))
    end
end

--- @registerMethod
function ScreenBase._OnSelectionChanged(self: ScreenBase)
    assert(self.tabContainer)
    assert(self.tabs)

    if self.currentTab then
        self.currentTab.visible = false
    end

    local tab = self.tabContainer.selectedButton
    if not tab then
        self.currentTab = nil
        return
    end

    local tabContents = assert(self.tabs:GetChild(tab:GetIndex())) :: Control
    tabContents.visible = true
    self.currentTab = tabContents
end

return ScreenBaseC
