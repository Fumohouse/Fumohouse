local Dock = require("Dock")
local PartDatabase = require("../../character/appearance/parts/PartDatabase")
local AppearanceManager = require("../../character/appearance/AppearanceManager")
local SinglePart = require("../../character/appearance/parts/SinglePart")

--- @class
--- @extends Control
--- @tool
--- @permissions FILE
local AppearanceSaver = {}
local AppearanceSaverC = gdclass(AppearanceSaver)

--- @classType AppearanceSaver
export type AppearanceSaver = Control & typeof(AppearanceSaver) & {
    folderField: LineEdit,
    selection: EditorSelection,
}

--- @registerMethod
function AppearanceSaver._Ready(self: AppearanceSaver)
    self.folderField = self:GetNode("Folder") :: LineEdit

    local plugin = (self:GetNode("../..") :: Dock.Dock).plugin
    self.selection = plugin:GetEditorInterface():GetSelection()
end

--- @registerMethod
function AppearanceSaver._OnButtonPressed(self: AppearanceSaver)
    -- Selection
    local selected = self.selection:GetSelectedNodes()
    if selected:IsEmpty() then
        return
    end

    local target = selected:Get(0) :: Node

    -- Prepare directory
    local folder = self.folderField.text
    assert(folder ~= "", "The folder field is required.")

    local folderPath = PartDatabase.PART_INFO_PATH..folder.."/"
    assert(not DirAccess.DirExistsAbsolute(folderPath), "The directory already exists.")

    DirAccess.MakeDirAbsolute(folderPath)

    -- Save
    local attachments = target:GetNode("Appearance")

    for _, attachment: Node in attachments:GetChildren() do
        if not attachment:IsA(BoneAttachment3D) then
            return
        end

        local bone: number?
        for boneEnum, name in AppearanceManager.ATTACHMENTS do
            if name == attachment.name then
                bone = boneEnum
                break
            end
        end

        assert(bone, `Bone not found for attachment {attachment.name}`)

        for _, part: Node3D in attachment:GetChildren() do
            local scenePath = part.sceneFilePath
            if scenePath == "" then
                push_warning(`Part {part.name} is not instantiated from a scene file.`)
                continue
            end

            if not String.BeginsWith(scenePath, SinglePart.BASE_PATH) then
                push_warning(`Part {part.name} is instantiated from a scene not under {SinglePart.BASE_PATH}.`)
            end

            scenePath = string.sub(scenePath, string.len(SinglePart.BASE_PATH) + 1)

            local partData = SinglePart.new() :: SinglePart.SinglePart
            partData.id = part.name
            partData.scenePath = scenePath
            partData.transform = part.transform
            partData.bone = bone

            save(
                partData,
                `{folderPath}{attachment.name}_{part.name}.tres`
            )
        end
    end
end

return AppearanceSaverC
