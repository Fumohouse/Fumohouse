local TransitionElement = require("../TransitionElement")

--- @class
--- @extends TransitionElement
--- @permissions FILE
local ChangelogScreen = {}
local ChangelogScreenC = gdclass(ChangelogScreen)

--- @classType ChangelogScreen
export type ChangelogScreen = TransitionElement.TransitionElement & typeof(ChangelogScreen) & {
    --- @property
    entries: Control,

    --- @property
    entryTitle: Label,
    --- @property
    entryContents: RichTextLabel,
}

local BASE_PATH = "res://ui/navigation/changelog_screen/entries/"

local function getEntryName(fileName: string)
    return String.Replace(String.GetBasename(fileName), ".", "/")
end

--- @registerMethod
function ChangelogScreen._Ready(self: ChangelogScreen)
    local dir = DirAccess.Open(BASE_PATH)
    assert(dir, "Failed to open changelog entries directory")

    dir:ListDirBegin()

    local files: {string} = {}
    local fileName = dir:GetNext()

    while fileName ~= "" do
        assert(not dir:CurrentIsDir())
        table.insert(files, fileName)
        fileName = dir:GetNext()
    end

    -- Sort reverse alphabetical
    table.sort(files, function(a, b) return a > b end)

    for _, file in files do
        local button = LinkButton.new()
        button.name = file
        button.text = getEntryName(file)

        button.pressed:Connect(Callable.new(self, "_OnEntryPressed"):Bind(file))

        self.entries:AddChild(button)
    end

    self:_OnEntryPressed(files[1])
end

--- @registerMethod
function ChangelogScreen._OnEntryPressed(self: ChangelogScreen, fileName: string)
    self.entryTitle.text = `Changelog for {getEntryName(fileName)}`

    local file = FileAccess.Open(BASE_PATH .. fileName, FileAccess.ModeFlags.READ)
    if file then
        self.entryContents.text = file:GetAsText()
    else
        self.entryContents.text = "Failed to load contents."
    end
end

return ChangelogScreenC
