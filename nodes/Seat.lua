local Character = require("../character/Character")

--- @class
--- @extends StaticBody3D
local Seat = {}
local SeatC = gdclass(Seat)

--- @classType Seat
export type Seat = StaticBody3D & typeof(Seat) & {
    --- @property
    --- @set SetOccupant
    --- @get GetOccupant
    occupant: RigidBody3D?,

    occupantInternal: RigidBody3D?,
    joint: Joint3D,
    marker: Marker3D,
    dismountMarker: Marker3D,
}

--- @registerMethod
function Seat._Ready(self: Seat)
    self.joint = self:GetNode("Joint") :: Joint3D
    self.marker = self:GetNode("Position") :: Marker3D
    self.dismountMarker = self:GetNode("DismountPosition") :: Marker3D
end

--- @registerMethod
function Seat.SetOccupant(self: Seat, occupant: RigidBody3D?)
    if self.occupant then
        -- Letting the character dismount at its current position drastically increases the probability
        -- of it getting stuck and recovery failing. That's bad!
        self.occupant.globalPosition = self.dismountMarker.globalPosition
    end

    if not occupant then
        self.joint.nodeB = ""
        self.occupantInternal = nil
        return
    end

    local seatPivot: Vector3
    if occupant:IsA(Character) then
        seatPivot = (occupant :: Character.Character).state:GetBottomPosition()
    else
        seatPivot = occupant.globalPosition
    end

    local pivotOffset = seatPivot - occupant.globalPosition
    occupant.globalTransform = self.marker.globalTransform:Translated(-pivotOffset)

    self.joint.nodeB = occupant:GetPath()
    self.occupantInternal = occupant
end

--- @registerMethod
function Seat.GetOccupant(self: Seat): RigidBody3D?
    return self.occupantInternal
end

return SeatC
