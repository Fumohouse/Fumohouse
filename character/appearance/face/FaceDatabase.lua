local FacePartStyle = require("FacePartStyle")
local EyeStyle = require("EyeStyle")

local FaceDatabaseImpl = {}
local FaceDatabase = gdclass("FaceDatabase", Resource)
    :RegisterImpl(FaceDatabaseImpl)

type FaceDatabaseT = {
    eyebrowStyles: TypedArray<FacePartStyle.FacePartStyle>,
    eyeStyles: TypedArray<EyeStyle.EyeStyle>,
    mouthStyles: TypedArray<FacePartStyle.FacePartStyle>,
}

export type FaceDatabase = Resource & FaceDatabaseT & typeof(FaceDatabaseImpl)

FaceDatabase:RegisterProperty("eyebrowStyles", Enum.VariantType.ARRAY)
    :TypedArray(FacePartStyle)

FaceDatabase:RegisterProperty("eyeStyles", Enum.VariantType.ARRAY)
    :TypedArray(EyeStyle)

FaceDatabase:RegisterProperty("mouthStyles", Enum.VariantType.ARRAY)
    :TypedArray(FacePartStyle)

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

function FaceDatabaseImpl.GetEye(self: FaceDatabase, name: string)
    return findByName(self.eyeStyles, name)
end

function FaceDatabaseImpl.GetMouth(self: FaceDatabase, name: string)
    return findByName(self.mouthStyles, name)
end

return FaceDatabase
