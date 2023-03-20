local Character = require("../character/Character")

local SeatImpl = {}
local Seat = gdclass(nil, StaticBody3D)
    :RegisterImpl(SeatImpl)

export type Seat = StaticBody3D & typeof(SeatImpl) & {
    occupant: string,
    occupantInternal: string,

    joint: Joint3D,
    marker: Marker3D,
    dismountMarker: Marker3D,
}

Seat:RegisterProperty("occupant", Enum.VariantType.NODE_PATH)
    :NodePath(RigidBody3D)
    :SetGet("SetOccupant", "GetOccupant")

function SeatImpl._Init(self: Seat)
    self.occupantInternal = ""
end

function SeatImpl._Ready(self: Seat)
    self.joint = self:GetNode("Joint") :: Joint3D
    self.marker = self:GetNode("Position") :: Marker3D
    self.dismountMarker = self:GetNode("DismountPosition") :: Marker3D
end

Seat:RegisterMethod("_Ready")

function SeatImpl.SetOccupant(self: Seat, occupant: string)
    if occupant == "" and self.occupant ~= "" then
        local oldOccupant = self:GetNode(self.occupant) :: Node3D
        -- Letting the character dismount at its current position drastically increases the probability
        -- of it getting stuck and recovery failing. That's bad!
        oldOccupant.globalPosition = self.dismountMarker.globalPosition

        self.joint.nodeB = ""
        self.occupantInternal = ""
        return
    end

    local node = self:GetNode(occupant) :: Node3D

    local seatPivot: Vector3
    if node:IsA(Character) then
        seatPivot = (node :: Character.Character).state:GetBottomPosition()
    else
        seatPivot = node.globalPosition
    end

    local pivotOffset = seatPivot - node.globalPosition
    node.globalTransform = self.marker.globalTransform:Translated(-pivotOffset)

    self.joint.nodeB = occupant
    self.occupantInternal = occupant
end

Seat:RegisterMethod("SetOccupant")
    :Args({ name = "occupant", type = Enum.VariantType.NODE_PATH })

function SeatImpl.GetOccupant(self: Seat)
    return self.occupantInternal
end

Seat:RegisterMethod("GetOccupant")
    :ReturnVal({ type = Enum.VariantType.NODE_PATH })

return Seat
