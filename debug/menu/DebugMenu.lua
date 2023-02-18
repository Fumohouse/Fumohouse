local AutosizeRichText = require("../../nodes/AutosizeRichText")

local DebugMenuImpl = {}
local DebugMenu = gdclass("DebugMenu", PanelContainer)
    :RegisterImpl(DebugMenuImpl)

export type DebugMenuEntry = {
    root: Control,
    label: RichTextLabel?,
    contents: RichTextLabel,
}

export type DebugMenuT = {
    vbox: VBoxContainer,

    entries: {[string]: DebugMenuEntry},
    menuName: string,
    action: string,
    menuVisible: boolean,
}

export type DebugMenu = PanelContainer & DebugMenuT & typeof(DebugMenuImpl)

function DebugMenuImpl._Init(obj: PanelContainer, tbl: DebugMenuT)
    tbl.entries = {}
    tbl.menuName = ""
    tbl.action = ""
    tbl.menuVisible = false
end

function DebugMenuImpl.updateVisibility(self: DebugMenu, visible: boolean)
    self.visible = visible
    self:SetProcess(visible)

    self.menuVisible = visible
end

function DebugMenuImpl._Ready(self: DebugMenu)
    self.vbox = self:GetNode("MarginContainer/VBoxContainer") :: VBoxContainer

    self:updateVisibility(self.menuVisible)

	-- Should process after anything being observed
    self.processPriority = 100
end

DebugMenu:RegisterMethod("_Ready")

function DebugMenuImpl._UnhandledInput(self: DebugMenu, event: InputEvent)
    if self.action ~= "" and event:IsActionPressed(self.action) then
        self:updateVisibility(not self.menuVisible)
    end
end

DebugMenu:RegisterMethodAST("_UnhandledInput")

local function createLabel(): RichTextLabel
    local label = AutosizeRichText.new() :: AutosizeRichText.AutosizeRichText

    label.bbcodeEnabled = true
    label.scrollActive = false
    label.autowrapMode = TextServer.AutowrapMode.OFF
    label.shortcutKeysEnabled = false

    label.clipContents = false

    return label
end

function DebugMenuImpl.AddEntry(self: DebugMenu, id: string, label: string?): DebugMenuEntry
    local root: Control
    local labelObj: RichTextLabel?
    local contents: RichTextLabel

    if label then
        local hbox = HBoxContainer.new()
        hbox:AddThemeConstantOverride("separation", 12)

        local labelText = createLabel()
        labelText.text = `[b]{label}[/b]`
        hbox:AddChild(labelText)

        local debugText = createLabel()
        hbox:AddChild(debugText)

        self.vbox:AddChild(hbox)

        root = hbox
        labelObj = labelText
        contents = debugText
    else
        local debugText = createLabel()
        self.vbox:AddChild(debugText)

        root = debugText
        contents = debugText
    end

    local entry =  {
        root = root,
        label = labelObj,
        contents = contents,
    }

    self.entries[id] = entry
    return entry
end

function DebugMenuImpl.SetVal(self: DebugMenu, id: string, contents: string)
    self.entries[id].contents.text = contents
end

return DebugMenu
