local PartData = require("scenes/character/appearance/parts/PartData")

local PartDatabaseImpl = {}
local PartDatabase = gdclass(nil, "Node")
	:Permissions(Enum.Permissions.FILE)
	:RegisterImpl(PartDatabaseImpl)

type PartDatabaseT = {
	parts: {[string]: PartData.PartData},
	partCount: number
}

export type PartDatabase = Node & PartDatabaseT & typeof(PartDatabaseImpl)

PartDatabaseImpl.PART_INFO_PATH = "res://resources/part_data/"

function PartDatabaseImpl._Init(obj: Node, tbl: PartDatabaseT)
	tbl.parts = {}
	tbl.partCount = 0
end

function PartDatabaseImpl.scanDir(self: PartDatabase, path: string)
	print("Scanning path: ", path)

	local dir = DirAccess.Open(path)
	if not is_instance_valid(dir) then
		error("Failed to open directory: "..path)
	end

	dir:ListDirBegin()

	local fileName = dir:GetNext()

	while fileName ~= "" do
		if dir:CurrentIsDir() then
			self:scanDir(path..fileName.."/")
		elseif strext.endswith(fileName, ".tres") then
			local partInfo: PartData.PartData = load(path..fileName)
			local id = partInfo.id

			if self.parts[id] ~= nil then
				error("Duplicate part ID: "..tostring(id))
			else
				print("\tFound part: "..tostring(id))
				self.parts[id] = partInfo
				self.partCount += 1
			end
		end

		fileName = dir:GetNext()
	end
end

function PartDatabaseImpl._Ready(self: PartDatabase)
	print("---- PartDatabase beginning load ----")
	self:scanDir(PartDatabase.PART_INFO_PATH)
	print(string.format("---- Finished loading %d parts. ----", self.partCount))
end

PartDatabase:RegisterMethod("_Ready")

function PartDatabaseImpl.GetPart(self: PartDatabase, id: string): PartData.PartData
	return self.parts[id]
end

PartDatabase:RegisterMethod("GetPart")
	:Args({ name = "id", type = Enum.VariantType.STRING })
	:ReturnVal({ type = Enum.VariantType.OBJECT })

return PartDatabase
