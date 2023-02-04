local Dock = require("addons/fumohouse/Dock")
local PartDatabase = require("scenes/character/appearance/parts/PartDatabase")
-- local AppearanceManager = require("scenes/character/appearance/AppearanceManager")
local SinglePart = require("scenes/character/appearance/parts/SinglePart")

-- TODO
local AppearanceManager = {
	ATTACHMENTS = {
		[SinglePart.Bone.TORSO] = "Torso",
		[SinglePart.Bone.HEAD] = "Head",
		[SinglePart.Bone.R_ARM] = "RArm",
		[SinglePart.Bone.L_ARM] = "LArm",
		[SinglePart.Bone.R_HAND] = "RHand",
		[SinglePart.Bone.L_HAND] = "LHand",
		[SinglePart.Bone.R_LEG] = "RLeg",
		[SinglePart.Bone.L_LEG] = "LLeg",
		[SinglePart.Bone.R_FOOT] = "RFoot",
		[SinglePart.Bone.L_FOOT] = "LFoot",
	}
}
-------

local AppearanceSaverImpl = {}
local AppearanceSaver = gdclass(nil, "Control")
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

	local plugin = (self:GetParent() :: Dock.Dock).plugin
	self.selection = plugin:GetEditorInterface():GetSelection()
end

AppearanceSaver:RegisterMethod("_Ready")

function AppearanceSaverImpl._OnButtonPressed(self: AppearanceSaver)
	-- Selection
	local selected = self.selection:GetSelectedNodes()
	if selected:IsEmpty() then
		return
	end

	local target: Node = selected[0]

	-- Prepare directory
	local folder = self.folderField.text
	if folder == "" then
		error("The folder field is required.")
	end

	local folderPath = PartDatabase.PART_INFO_PATH..folder.."/"
	if not DirAccess.DirExistsAbsolute(folderPath) then
		DirAccess.MakeDirAbsolute(folderPath)
	else
		error("The directory already exists.")
	end

	local directory = DirAccess.Open(folderPath)
	if not is_instance_valid(directory) then
		error("Failed to open directory: "..folderPath)
	end

	-- Save
	local attachments: Node = target:GetNode("Appearance")

	for i, attachment: Node in attachments:GetChildren() do
		if not attachment:IsClass("BoneAttachment3D") then
			return
		end

		local bone: number

		for boneEnum, name in AppearanceManager.ATTACHMENTS do
			if name == attachment.name then
				bone = boneEnum
				break
			end
		end

		for j, part: Node3D in attachment:GetChildren() do
			local scenePath = part.sceneFilePath
			if scenePath == "" then
				push_warning(string.format("Part %s is not instantiated from a scene file.", part.name))
				continue
			end

			if not strext.startswith(scenePath, SinglePart.BASE_PATH) then
				push_warning(string.format("Part %s is instantiated from a scene not under %s.", part.name, SinglePart.BASE_PATH))
			end

			scenePath = string.sub(scenePath, string.len(SinglePart.BASE_PATH) + 1)

			local partData = SinglePart.new() :: SinglePart.SinglePart
			partData.id = part.name
			partData.scenePath = scenePath
			partData.transform = part.transform
			partData.bone = bone

			ResourceSaver.GetSingleton():Save(
				partData,
				folderPath..string.format("%s_%s.tres", attachment.name, part.name)
			)
		end
	end
end

AppearanceSaver:RegisterMethod("_OnButtonPressed")

return AppearanceSaver
