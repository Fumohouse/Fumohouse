--[[
    Controls whether the character is in ragdoll mode.
]]

local Move = require("Move.mod")
local Seat = require("../../nodes/Seat")
local MotionState = require("../MotionState.mod")
local Utils = require("../../utils/Utils.mod")

local Ragdoll = setmetatable({
    ID = "ragdoll",
}, MotionState.MotionProcessor)

Ragdoll.__index = Ragdoll

function Ragdoll.new()
    local self = {}

    self.currentSeat = nil :: Seat.Seat?
    self.seatDebounceLeft = 0
    self.lastSeat = nil :: Seat.Seat?

    self.options = {
        seatDebounce = 3,
    }

    return setmetatable(self, Ragdoll)
end

local function handleState(state: MotionState.MotionState, action: string, characterState: number)
    local ctx = state.ctx

    if Utils.DoGameInput(state.node) and Input.singleton:IsActionJustPressed(action) then
        if state:IsState(characterState) then
            state:SetRagdoll(false)
        elseif not state.isRagdoll then
            ctx:SetState(characterState)
            state:SetRagdoll(true)
        end
    elseif state.isRagdoll and state:IsState(characterState) then
        -- Maintain state
        ctx:SetState(characterState)
    end
end

function Ragdoll.Process(self: Ragdoll, state: MotionState.MotionState, delta: number)
    handleState(state, "move_sit", MotionState.CharacterState.SITTING)

    local ctx = state.ctx

    -- Seat handling
    if self.currentSeat then
        -- Dismount
        if not state.isRagdoll then
            self.lastSeat = self.currentSeat
            self.seatDebounceLeft = self.options.seatDebounce

            self.currentSeat.occupant = nil
            self.currentSeat = nil
        end
    else
        -- Debounce
        if self.seatDebounceLeft > 0 then
            self.seatDebounceLeft = math.max(0, self.seatDebounceLeft - delta)

            if self.seatDebounceLeft == 0 then
                self.lastSeat = nil
            end
        end

        -- Find seat
        if not state.isRagdoll then
            for _, body in state.intersections.bodies do
                -- TODO: Luau 570
                if (not self.lastSeat or body ~= self.lastSeat :: CollisionObject3D) and body:IsA(Seat) then
                    state:SetRagdoll(true)
                    ctx:SetState(MotionState.CharacterState.SITTING)
                    ctx:CancelProcessor(Move.ID)

                    local seat = body :: Seat.Seat
                    seat.occupant = state.node
                    self.currentSeat = seat
                end
            end
        end
    end
end

export type Ragdoll = typeof(Ragdoll.new())
return Ragdoll
