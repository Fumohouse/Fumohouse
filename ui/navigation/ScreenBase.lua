local ButtonTabContainer = require("../../nodes/ButtonTabContainer")
local TransitionElement = require("TransitionElement")

--- @class
--- @extends TransitionElement
local ScreenBase = {}
local ScreenBaseC = gdclass(ScreenBase)

--- @classType ScreenBase
export type ScreenBase = TransitionElement.TransitionElement & typeof(ScreenBase) & {
    --- @property
    tabContainer: ButtonTabContainer.ButtonTabContainer?,
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

        self.tabContainer.selection = 0
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

    local tabIdx = self.tabContainer.selection
    if tabIdx < 0 then
        self.currentTab = nil
        return
    end

    local tab = assert(self.tabs:GetChild(self.tabContainer.selection)) :: Control
    tab.visible = true
    self.currentTab = tab
end

return ScreenBaseC
