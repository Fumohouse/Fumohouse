--[[
    Controls whether the character is in ragdoll mode.
]]

local Move = require("Move.mod")
local Seat = require("../../nodes/Seat")
local MotionState = require("../MotionState.mod")

local Ragdoll = { ID = "ragdoll" }
Ragdoll.__index = Ragdoll

function Ragdoll.new()
    local self = {}

    self.state = (nil :: any) :: MotionState.MotionState

    self.currentSeat = nil :: Seat.Seat?
    self.seatDebounceLeft = 0
    self.lastSeat = nil :: Seat.Seat?

    self.options = {
        seatDebounce = 3,
    }

    return setmetatable(self, Ragdoll)
end

function Ragdoll.Initialize(self: Ragdoll, state: MotionState.MotionState)
    self.state = state
end

local function handleState(state: MotionState.MotionState, action: boolean, characterState: number)
    local ctx = state.ctx

    if action then
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
    if state:IsRemoteCharacter() then
        return
    end

    local ctx = state.ctx
    handleState(state, ctx.motion.sit, MotionState.CharacterState.SITTING)

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
                    local seat = body :: Seat.Seat

                    if not seat.occupant then
                        state:SetRagdoll(true)
                        ctx:SetState(MotionState.CharacterState.SITTING)
                        ctx:CancelProcessor(Move.ID)

                        seat.occupant = state.node
                        self.currentSeat = seat
                    end
                end
            end
        end
    end
end

function Ragdoll.GetState(self: Ragdoll)
    local state = Dictionary.new()

    state:Set("cs", if self.currentSeat then self.currentSeat:GetPath() else "")
    state:Set("dl", self.seatDebounceLeft)
    state:Set("ls", if self.lastSeat then self.lastSeat:GetPath() else "")

    return state
end

function Ragdoll.LoadState(self: Ragdoll, state: Variant)
    assert(typeof(state) == "Dictionary")

    if state:Has("cs") then
        local val = state:Get("cs")
        assert(type(val) == "string")

        if val == "" then
            if self.currentSeat then
                self.currentSeat.occupant = nil
                self.currentSeat = nil

                self.state:SetRagdoll(false)
            end
        else
            local node = self.state.node:GetNodeOrNull(val)
            assert(not node or node:IsA(Seat))

            self.currentSeat = node :: Seat.Seat?

            if self.currentSeat then
                self.state:SetRagdoll(true)
                self.state.state = bit32.bor(self.state.state, MotionState.CharacterState.SITTING)

                self.currentSeat.occupant = self.state.node
            end
        end
    end

    if state:Has("dl") then
        local val = state:Get("dl")
        assert(type(val) == "number")
        self.seatDebounceLeft = val
    end

    if state:Has("ls") then
        local val = state:Get("ls")
        assert(type(val) == "string")

        if val == "" then
            self.lastSeat = nil
        else
            local node = self.state.node:GetNodeOrNull(val)
            assert(not node or node:IsA(Seat))

            self.lastSeat = node :: Seat.Seat?
        end
    end
end

export type Ragdoll = typeof(Ragdoll.new())
return Ragdoll
