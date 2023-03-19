local Dock = require("Dock")
local PartDatabase = require("../../character/appearance/parts/PartDatabase")
local AppearanceManager = require("../../character/appearance/AppearanceManager")
local SinglePart = require("../../character/appearance/parts/SinglePart")

local AppearanceSaverImpl = {}
local AppearanceSaver = gdclass(nil, Control)
    :Permissions(Enum.Permissions.FILE)
    :Tool(true)
    :RegisterImpl(AppearanceSaverImpl)

type AppearanceSaverT = {
    folderField: LineEdit,
    selection: EditorSelection,
}

export type AppearanceSaver = Control & AppearanceSaverT

function AppearanceSaverImpl._Ready(self: AppearanceSaver)
    self.folderField = self:GetNode("Folder") :: LineEdit

    local plugin = (self:GetNode("../..") :: Dock.Dock).plugin
    self.selection = plugin:GetEditorInterface():GetSelection()
end

AppearanceSaver:RegisterMethod("_Ready")

function AppearanceSaverImpl._OnButtonPressed(self: AppearanceSaver)
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

            if not strext.startswith(scenePath, SinglePart.BASE_PATH) then
                push_warning(`Part {part.name} is instantiated from a scene not under {SinglePart.BASE_PATH}.`)
            end

            scenePath = string.sub(scenePath, string.len(SinglePart.BASE_PATH) + 1)

            local partData = SinglePart.new() :: SinglePart.SinglePart
            partData.id = part.name
            partData.scenePath = scenePath
            partData.transform = part.transform
            partData.bone = bone

            ResourceSaver.GetSingleton():Save(
                partData,
                `{folderPath}{attachment.name}_{part.name}.tres`
            )
        end
    end
end

AppearanceSaver:RegisterMethod("_OnButtonPressed")

return AppearanceSaver
