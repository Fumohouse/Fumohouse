local ScreenBase = require("../ScreenBase")
local Utils = require("../../../utils/Utils.mod")
local CopyrightParser = require("../../../utils/CopyrightParser.mod")
local MapManifest = require("../../../map_system/MapManifest")

local MapManagerM = require("../../../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

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
    mapCopyrightTitle: Label,
    --- @property
    mapCopyrightText: RichTextLabel,

    --- @property
    infoPopup: Window,
    --- @property
    infoTitle: Label,
    --- @property
    infoText: RichTextLabel,

    copyrightInfo: CopyrightParser.CopyrightFile,
    mapCopyrightInfo: CopyrightParser.CopyrightFile?,
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

local function parseCopyrightInfo(path: string)
    local file = FileAccess.Open(path, FileAccess.ModeFlags.READ)
    assert(file, `Failed to open {path}`)

    local copyrightInfo = CopyrightParser.Parse(file:GetAsText())

    local copyrightInfoText = ""

    for i, filesInfo in copyrightInfo.files do
        copyrightInfoText ..= string.format([[
[b]%s[/b]
    [b]Files[/b]: [code]%s[/code]
    [b]Copyright[/b]: %s
    [b]License[/b]: [url=%s]%s[/url]
        ]], filesInfo.comment, filesInfo.files, hangingIndent(filesInfo.copyright), filesInfo.license, filesInfo.license)

        if i ~= #copyrightInfo.files then
            copyrightInfoText ..= "\n"
        end
    end

    return copyrightInfo, copyrightInfoText
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

    local copyrightInfo, copyrightInfoText = parseCopyrightInfo("res://COPYRIGHT.txt")

    self.copyrightInfo = copyrightInfo
    self.copyrightText.text = copyrightInfoText

    self.copyrightText.metaClicked:Connect(Callable.new(self, "_OnCopyrightMetaClicked"))
    self.mapCopyrightText.metaClicked:Connect(Callable.new(self, "_OnMapCopyrightMetaClicked"))

    self:_OnMapChanged(MapManager.currentMap and MapManager.currentMap.manifest)
    MapManager.mapChanged:Connect(Callable.new(self, "_OnMapChanged"))
end

--- @registerMethod
function InfoScreen._OnMapChanged(self: InfoScreen, manifest: MapManifest.MapManifest?)
    local actualManifest = manifest or MapManager:GetTitleMap().manifest

    self.mapCopyrightTitle.text = `{actualManifest.author} - {actualManifest.name} Copyright Information`

    if FileAccess.FileExists(actualManifest.copyrightFile) then
        local copyrightInfo, copyrightInfoText = parseCopyrightInfo(actualManifest.copyrightFile)
        self.mapCopyrightInfo = copyrightInfo
        self.mapCopyrightText.text = copyrightInfoText
    else
        self.mapCopyrightInfo = nil
        self.mapCopyrightText.text = "This map does not provide any copyright information."
    end
end

function InfoScreen.openLicensePopup(self: InfoScreen, key: string, license: CopyrightParser.CopyrightLicense?)
    self.infoPopup.size = Vector2i.new(800, 640)

    self.infoTitle.text = `{key} License Text`
    self.infoText.text = if license then license.text else "License text not found."

    self.infoPopup.visible = true
end

--- @registerMethod
function InfoScreen._OnCopyrightMetaClicked(self: InfoScreen, meta: string)
    self:openLicensePopup(meta, self.copyrightInfo.licenses[meta])
end

--- @registerMethod
function InfoScreen._OnMapCopyrightMetaClicked(self: InfoScreen, meta: string)
    assert(self.mapCopyrightInfo)
    self:openLicensePopup(meta, self.mapCopyrightInfo.licenses[meta])
end

return InfoScreenC
