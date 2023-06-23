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
    occupant: NodePathConstrained<RigidBody3D>,
    occupantInternal: string,

    joint: Joint3D,
    marker: Marker3D,
    dismountMarker: Marker3D,
}

function Seat._Init(self: Seat)
    self.occupantInternal = ""
end

--- @registerMethod
function Seat._Ready(self: Seat)
    self.joint = self:GetNode("Joint") :: Joint3D
    self.marker = self:GetNode("Position") :: Marker3D
    self.dismountMarker = self:GetNode("DismountPosition") :: Marker3D
end

--- @registerMethod
function Seat.SetOccupant(self: Seat, occupant: NodePath)
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

--- @registerMethod
function Seat.GetOccupant(self: Seat): NodePath
    return self.occupantInternal
end

return SeatC
