local InfoTableImpl = {}
local InfoTable = gdclass("InfoTable", VBoxContainer)
    :RegisterImpl(InfoTableImpl)

export type InfoTableEntry = {
    root: Control,
    label: RichTextLabel?,
    contents: RichTextLabel,
}

type InfoTableT = {
    entries: {[string]: InfoTableEntry},
}

export type InfoTable = VBoxContainer & InfoTableT & typeof(InfoTableImpl)

function InfoTableImpl._Init(obj: VBoxContainer, tbl: InfoTableT)
    tbl.entries = {}
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

function InfoTableImpl.AddEntry(self: InfoTable, id: string, label: string?)
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

function InfoTableImpl.SetVal(self: InfoTable, id: string, contents: string)
    self.entries[id].contents.text = contents
end

return InfoTable
