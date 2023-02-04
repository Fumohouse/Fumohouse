local FacePartStyle = require("scenes/character/appearance/face/FacePartStyle")
local EyeStyle = require("scenes/character/appearance/face/EyeStyle")

local FaceDatabaseImpl = {}
local FaceDatabase = gdclass("FaceDatabase", "Resource")
    :RegisterImpl(FaceDatabaseImpl)

type FaceDatabaseT = {
    eyebrowStyles: TypedArray<FacePartStyle.FacePartStyle>,
    eyeStyles: TypedArray<EyeStyle.EyeStyle>,
    mouthStyles: TypedArray<FacePartStyle.FacePartStyle>,
}

export type FaceDatabase = Resource & FaceDatabaseT & typeof(FaceDatabaseImpl)

FaceDatabase:RegisterProperty("eyebrowStyles", Enum.VariantType.ARRAY)
    :TypedArray("Resource", true)

FaceDatabase:RegisterProperty("eyeStyles", Enum.VariantType.ARRAY)
    :TypedArray("Resource", true)

FaceDatabase:RegisterProperty("mouthStyles", Enum.VariantType.ARRAY)
    :TypedArray("Resource", true)

local function findByName<T>(list: TypedArray<T>, name: string): T?
    for i, item in list do
        if item.name == name then
            return item
        end
    end

    return nil
end

function FaceDatabaseImpl.GetEyebrow(self: FaceDatabase, name: string)
    return findByName(self.eyebrowStyles, name)
end

FaceDatabase:RegisterMethodAST("GetEyebrow")

function FaceDatabaseImpl.GetEye(self: FaceDatabase, name: string)
    return findByName(self.eyeStyles, name)
end

FaceDatabase:RegisterMethodAST("GetEye")

function FaceDatabaseImpl.GetMouth(self: FaceDatabase, name: string)
    return findByName(self.mouthStyles, name)
end

FaceDatabase:RegisterMethodAST("GetMouth")

return FaceDatabase
