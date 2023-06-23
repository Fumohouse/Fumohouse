local FacePartStyle = require("FacePartStyle")
local EyeStyle = require("EyeStyle")

--- @class FaceDatabase
--- @extends Resource
local FaceDatabase = {}
local FaceDatabaseC = gdclass(FaceDatabase)

--- @classType FaceDatabase
export type FaceDatabase = Resource & typeof(FaceDatabase) & {
    --- @property
    eyebrowStyles: TypedArray<FacePartStyle.FacePartStyle>,

    --- @property
    eyeStyles: TypedArray<EyeStyle.EyeStyle>,

    --- @property
    mouthStyles: TypedArray<FacePartStyle.FacePartStyle>,
}

local function findByName<T>(list: TypedArray<T>, name: string): T?
    for i, item in list do
        if item.name == name then
            return item
        end
    end

    return nil
end

function FaceDatabase.GetEyebrow(self: FaceDatabase, name: string)
    return findByName(self.eyebrowStyles, name)
end

function FaceDatabase.GetEye(self: FaceDatabase, name: string)
    return findByName(self.eyeStyles, name)
end

function FaceDatabase.GetMouth(self: FaceDatabase, name: string)
    return findByName(self.mouthStyles, name)
end

return FaceDatabaseC
