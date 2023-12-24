local ScreenBase = require("../ScreenBase")
local Utils = require("../../../utils/Utils.mod")
local CopyrightParser = require("../../../utils/CopyrightParser.mod")

--- @class
--- @permissions FILE
--- @extends ScreenBase
local InfoScreen = {}
local InfoScreenC = gdclass(InfoScreen)

--- @classType InfoScreen
export type InfoScreen = ScreenBase.ScreenBase & typeof(InfoScreen) & {
    --- @property
    versionText: RichTextLabel,
    --- @property
    copyrightText: RichTextLabel,

    --- @property
    licensePopup: Window,
    --- @property
    licenseTitle: Label,
    --- @property
    licenseText: RichTextLabel,

    copyrightInfo: CopyrightParser.CopyrightFile,
}

local function hangingIndent(str: string)
    local output = ""

    local split = string.split(str, "\n")

    for i, line in split do
        output ..= line

        if i ~= #split then
            output ..= "\n\t\t"
        end
    end

    return output
end

--- @registerMethod
function InfoScreen._Ready(self: InfoScreen)
    ScreenBase._Ready(self)

    local verInfo = Engine.singleton:GetVersionInfo()
    local major, minor, patch =
        verInfo:Get("major") :: number, verInfo:Get("minor") :: number, verInfo:Get("patch") :: number

    self.versionText.text = `[center][b]Version[/b]: {Utils.stageName} {Utils.version}, [b]Godot version[/b]: {major}.{minor}.{patch}[/center]`

    local file = FileAccess.Open("res://COPYRIGHT.txt", FileAccess.ModeFlags.READ)
    assert(file, "Failed to open COPYRIGHT.txt")

    self.copyrightInfo = CopyrightParser.Parse(file:GetAsText())

    local copyrightInfoText = ""

    for i, filesInfo in self.copyrightInfo.files do
        copyrightInfoText ..= string.format([[
[b]%s[/b]
    [b]Files[/b]: [code]%s[/code]
    [b]Copyright[/b]: %s
    [b]License[/b]: [url=%s]%s[/url]
        ]], filesInfo.comment, filesInfo.files, hangingIndent(filesInfo.copyright), filesInfo.license, filesInfo.license)

        if i ~= #self.copyrightInfo.files then
            copyrightInfoText ..= "\n"
        end
    end

    self.copyrightText.text = copyrightInfoText
    self.copyrightText.metaClicked:Connect(Callable.new(self, "_OnCopyrightMetaClicked"))
end

--- @registerMethod
function InfoScreen._OnCopyrightMetaClicked(self: InfoScreen, meta: string)
    local license = assert(self.copyrightInfo.licenses[meta])

    self.licensePopup.size = Vector2i.new(800, 640)

    self.licenseTitle.text = `{license.id} License Text`
    self.licenseText.text = license.text

    self.licensePopup.visible = true
end

return InfoScreenC
