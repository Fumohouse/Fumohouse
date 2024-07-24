local PartData = require("PartData")

--- @class
--- @extends Node
--- @permissions FILE
local PartDatabase = {}
local PartDatabaseC = gdclass(PartDatabase)

export type PartDatabase = Node & typeof(PartDatabase) & {
    parts: {[string]: PartData.PartData},
    partCount: number
}

PartDatabase.PART_INFO_PATH = "res://resources/part_data/"

function PartDatabase._Init(self: PartDatabase)
    self.parts = {}
    self.partCount = 0
end

function PartDatabase.scanDir(self: PartDatabase, path: string)
    print("Scanning path: ", path)

    local dir = DirAccess.Open(path)
    assert(dir, `Failed to open directory: {path}`)

    dir:ListDirBegin()

    local fileName = dir:GetNext()

    while fileName ~= "" do
        if dir:CurrentIsDir() then
            self:scanDir(path..fileName.."/")
        elseif String.EndsWith(fileName, ".tres") then
            local partInfo: PartData.PartData = assert(load(path..fileName))
            local id = partInfo.id

            if self.parts[id] then
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

--- @registerMethod
function PartDatabase._Ready(self: PartDatabase)
    print("---- PartDatabase beginning load ----")
    self:scanDir(PartDatabase.PART_INFO_PATH)
    print(`---- Finished loading {self.partCount} parts. ----`)
end

function PartDatabase.GetPart(self: PartDatabase, id: string): PartData.PartData?
    return self.parts[id]
end

return PartDatabaseC
