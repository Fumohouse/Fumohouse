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

    --- @property
    marker: Node3D,

    occupantInternal: RigidBody3D?,
    occupantMode: number,
}

--- @registerMethod
function Seat.SetOccupant(self: Seat, occupant: RigidBody3D?)
    if self.occupant ~= occupant then
        if self.occupant then
            PhysicsServer3D.singleton:BodySetMode(self.occupant:GetRid(), self.occupantMode)
        end

        if occupant then
            self.occupantMode = PhysicsServer3D.singleton:BodyGetMode(occupant:GetRid())
            PhysicsServer3D.singleton:BodySetMode(occupant:GetRid(), PhysicsServer3D.BodyMode.STATIC)
        end

        self.occupantInternal = occupant
    end

    if occupant then
        local seatPivot: Vector3
        if occupant:IsA(Character) then
            seatPivot = (occupant :: Character.Character).state:GetBottomPosition()
        else
            seatPivot = occupant.globalPosition
        end

        local pivotOffset = seatPivot - occupant.globalPosition
        occupant.globalTransform = self.marker.globalTransform:Translated(-pivotOffset)
    end
end

--- @registerMethod
function Seat.GetOccupant(self: Seat): RigidBody3D?
    return self.occupantInternal
end

return SeatC
