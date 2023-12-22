local NumberType = {
    S8 = 0,
    S16 = 1,
    S32 = 2,
    S64 = 3,

    U8 = 4,
    U16 = 5,
    U32 = 6,
    U64 = 7,

    HALF = 8,
    FLOAT = 9,
    DOUBLE = 10,
}

export type SerDeImpl = {
    __index: SerDeImpl,

    Seek: (self: SerDe, position: number) -> (),
    SerDe: <T>(self: SerDe, value: T, numberType: number?) -> T,

    [any]: any,
}

export type SerDe = typeof(setmetatable({}, {} :: SerDeImpl))

local Serializer = {}
Serializer.__index = Serializer

function Serializer.new()
    local self = {}

    self.buffer = PackedByteArray.new()
    self.position = 0

    return setmetatable(self, Serializer)
end

function Serializer.Seek(self: Serializer, position: number)
    self.position = position
end

function Serializer.EnsureCapacity(self: Serializer, capacity: number)
    local currSize = self.buffer:Size()

    if currSize > self.position + capacity then
        return
    end

    self.buffer:Resize(math.max(currSize + capacity, currSize * 2))
end

function Serializer.WriteBuffer(self: Serializer, buffer: PackedByteArray)
    local size = buffer:Size()
    self:EnsureCapacity(size)

    for i = 0, size - 1 do
        self.buffer:Set(self.position + i, buffer:Get(i))
    end

    self.position += size
end

function Serializer.SerDe<T>(self: Serializer, value: T, numberType: number?): T
    if type(value) == "boolean" then
        self:EnsureCapacity(1)
        self.buffer:EncodeU8(self.position, if value then 1 else 0)
        self.position += 1
    elseif type(value) == "number" then
        if numberType == NumberType.S8 then
            self:EnsureCapacity(1)
            self.buffer:EncodeS8(self.position, value)
            self.position += 1
        elseif numberType == NumberType.S16 then
            self:EnsureCapacity(2)
            self.buffer:EncodeS16(self.position, value)
            self.position += 2
        elseif numberType == NumberType.S32 then
            self:EnsureCapacity(4)
            self.buffer:EncodeS32(self.position, value)
            self.position += 4
        elseif numberType == NumberType.S64 then
            self:EnsureCapacity(8)
            self.buffer:EncodeS64(self.position, value)
            self.position += 8
        elseif numberType == NumberType.U8 then
            self:EnsureCapacity(1)
            self.buffer:EncodeU8(self.position, value)
            self.position += 1
        elseif numberType == NumberType.U16 then
            self:EnsureCapacity(2)
            self.buffer:EncodeU16(self.position, value)
            self.position += 2
        elseif numberType == NumberType.U32 then
            self:EnsureCapacity(4)
            self.buffer:EncodeU32(self.position, value)
            self.position += 4
        elseif numberType == NumberType.U64 then
            self:EnsureCapacity(8)
            self.buffer:EncodeU64(self.position, value)
            self.position += 8
        elseif numberType == NumberType.HALF then
            self:EnsureCapacity(2)
            self.buffer:EncodeHalf(self.position, value)
            self.position += 2
        elseif numberType == NumberType.FLOAT then
            self:EnsureCapacity(4)
            self.buffer:EncodeFloat(self.position, value)
            self.position += 4
        else
            self:EnsureCapacity(8)
            self.buffer:EncodeDouble(self.position, value)
            self.position += 8
        end
    elseif type(value) == "string" then
        local buffer = String.ToUtf8Buffer(value)
        local size = buffer:Size()

        self:EnsureCapacity(4 + size)
        self:SerDe(size, NumberType.U32)
        self:WriteBuffer(buffer)
    elseif gdtypeof(value) then
        local buffer = var_to_bytes(value :: any)
        self:WriteBuffer(buffer)
    else
        error("No suitable type found")
    end

    return value
end

function Serializer.Write(self: Serializer): PackedByteArray
    self.buffer:Resize(self.position)
    return self.buffer
end

export type Serializer = typeof(Serializer.new())

local Deserializer = {}
Deserializer.__index = Deserializer

function Deserializer.new(buffer: PackedByteArray)
    local self = {}

    self.buffer = buffer
    self.position = 0

    return setmetatable(self, Deserializer)
end

function Deserializer.Seek(self: Deserializer, position: number)
    self.position = position
end

function Deserializer.AtEnd(self: Deserializer)
    return self.position == self.buffer:Size()
end

function Deserializer.EnsureCapacity(self: Deserializer, capacity: number)
    assert(self.buffer:Size() >= self.position + capacity, "Unexpected end of buffer")
end

function Deserializer.SerDe<T>(self: Deserializer, value: T, numberType: number?): T
    local ret: any

    if type(value) == "boolean" then
        self:EnsureCapacity(1)
        ret = self.buffer:DecodeU8(self.position) == 1
        self.position += 1
    elseif type(value) == "number" then
        if numberType == NumberType.S8 then
            self:EnsureCapacity(1)
            ret = self.buffer:DecodeU8(self.position)
            self.position += 1
        elseif numberType == NumberType.S16 then
            self:EnsureCapacity(2)
            ret = self.buffer:DecodeS16(self.position)
            self.position += 2
        elseif numberType == NumberType.S32 then
            self:EnsureCapacity(4)
            ret = self.buffer:DecodeS32(self.position)
            self.position += 4
        elseif numberType == NumberType.S64 then
            self:EnsureCapacity(8)
            ret = self.buffer:DecodeS64(self.position)
            self.position += 8
        elseif numberType == NumberType.U8 then
            self:EnsureCapacity(1)
            ret = self.buffer:DecodeU8(self.position)
            self.position += 1
        elseif numberType == NumberType.U16 then
            self:EnsureCapacity(2)
            ret = self.buffer:DecodeU16(self.position)
            self.position += 2
        elseif numberType == NumberType.U32 then
            self:EnsureCapacity(4)
            ret = self.buffer:DecodeU32(self.position)
            self.position += 4
        elseif numberType == NumberType.U64 then
            self:EnsureCapacity(8)
            ret = self.buffer:DecodeU64(self.position)
            self.position += 8
        elseif numberType == NumberType.HALF then
            self:EnsureCapacity(2)
            ret = self.buffer:DecodeHalf(self.position)
            self.position += 2
        elseif numberType == NumberType.FLOAT then
            self:EnsureCapacity(4)
            ret = self.buffer:DecodeFloat(self.position)
            self.position += 4
        else
            self:EnsureCapacity(8)
            ret = self.buffer:DecodeDouble(self.position)
            self.position += 8
        end
    elseif type(value) == "string" then
        local size = self:SerDe(0, NumberType.U32)
        self:EnsureCapacity(size)

        local stringBuffer = self.buffer:Slice(self.position, self.position + size)
        ret = stringBuffer:GetStringFromUtf8()
        self.position += size
    elseif gdtypeof(value) then
        assert(self.buffer:HasEncodedVar(self.position), "No Variant at this offset")

        ret = self.buffer:DecodeVar(self.position)
        self.position += self.buffer:DecodeVarSize(self.position)
    else
        error("No suitable type found")
    end

    return ret
end

export type Deserializer = typeof(Deserializer.new(PackedByteArray.new()))

return {
    NumberType = NumberType,
    Serializer = Serializer,
    Deserializer = Deserializer,
}
