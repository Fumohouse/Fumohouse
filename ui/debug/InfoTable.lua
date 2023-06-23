--- @class InfoTable
--- @extends VBoxContainer
local InfoTable = {}
local InfoTableC = gdclass(InfoTable)

export type InfoTableEntry = {
    root: Control,
    label: RichTextLabel?,
    contents: RichTextLabel,
}

--- @classType InfoTable
export type InfoTable = VBoxContainer & typeof(InfoTable) & {
    entries: {[string]: InfoTableEntry},
}

function InfoTable._Init(self: InfoTable)
    self.entries = {}
end

local function createLabel()
    local label = RichTextLabel.new()

    label.fitContent = true
    label.bbcodeEnabled = true
    label.scrollActive = false
    label.autowrapMode = TextServer.AutowrapMode.OFF
    label.shortcutKeysEnabled = false
    label.mouseFilter = Control.MouseFilter.PASS

    label.clipContents = false

    return label
end

function InfoTable.AddEntry(self: InfoTable, id: string, label: string?)
    local entry: InfoTableEntry

    if label then
        local hbox = HBoxContainer.new()
        hbox:AddThemeConstantOverride("separation", 12)

        local labelText = createLabel()
        labelText.text = `[b]{label}[/b]`
        hbox:AddChild(labelText)

        local contentsText = createLabel()
        hbox:AddChild(contentsText)

        self:AddChild(hbox)

        entry = {
            root = hbox,
            label = labelText,
            contents = contentsText,
        }
    else
        local contentsText = createLabel()
        self:AddChild(contentsText)

        entry = {
            root = contentsText,
            contents = contentsText,
        }
    end

    self.entries[id] = entry
    return entry
end

function InfoTable.SetVal(self: InfoTable, id: string, contents: string)
    self.entries[id].contents.text = contents
end

return InfoTableC
