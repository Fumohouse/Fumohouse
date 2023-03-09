--[[
    Updates animations on a Character.
]]

local Character = require("../Character")
local HorizontalMotion = require("HorizontalMotion.mod")
local LadderMotion = require("LadderMotion.mod")
local MotionState = require("../MotionState.mod")

local CharacterAnimator = setmetatable({
    ID = "animator",
}, MotionState.MotionProcessor)

CharacterAnimator.__index = CharacterAnimator

local MainTransition = {
    BASE = "base",
    IDLE = "idle",
    SIT = "sit",
    HORIZONTAL = "horizontal",
    VERTICAL = "vertical",
}

local VerticalTransition = {
    FALL = "fall",
    CLIMB = "climb",
}

local WALK_SPEED = "parameters/walk_speed/scale"
local CLIMB_SPEED = "parameters/climb_speed/scale"

local TRANSITION_MAIN = "parameters/main/transition_request"
local TRANSITION_VERTICAL = "parameters/vertical/transition_request"

local JUMP = "parameters/jump_oneshot/request"

local STATES: { {
    state: number,
    properties: {[string]: any},
} } = {
    {
        state = MotionState.CharacterState.SITTING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.SIT,
        }
    },
    {
        state = MotionState.CharacterState.CLIMBING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.VERTICAL,
            [TRANSITION_VERTICAL] = VerticalTransition.CLIMB,
            [JUMP] = AnimationNodeOneShot.OneShotRequest.NONE,
        }
    },
    {
        state = MotionState.CharacterState.FALLING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.VERTICAL,
            [TRANSITION_VERTICAL] = VerticalTransition.FALL,
            [JUMP] = AnimationNodeOneShot.OneShotRequest.NONE,
        }
    },
    {
        state = MotionState.CharacterState.JUMPING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.VERTICAL,
            [TRANSITION_VERTICAL] = VerticalTransition.FALL,
            [JUMP] = AnimationNodeOneShot.OneShotRequest.FIRE,
        }
    },
    {
        state = MotionState.CharacterState.WALKING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.HORIZONTAL,
        }
    },
    {
        state = MotionState.CharacterState.IDLE,
        properties = {
            [TRANSITION_MAIN] = MainTransition.IDLE,
        }
    },
}

function CharacterAnimator.new()
    local self = {}

    self.character = nil :: Character.Character?
    self.animator = nil :: AnimationTree?
    self.horizontalMotion = nil :: HorizontalMotion.HorizontalMotion?
    self.ladderMotion = nil :: LadderMotion.LadderMotion?

    self.state = MotionState.CharacterState.NONE

    return setmetatable(self, CharacterAnimator)
end

function CharacterAnimator.Initialize(self: CharacterAnimator, state: MotionState.MotionState)
    if state.node:IsA(Character) then
        self.character = state.node :: Character.Character
        self.animator = state.node:GetNodeOrNull("Rig/Armature/AnimationTree") :: AnimationTree?

        self.horizontalMotion = state:GetMotionProcessor(HorizontalMotion.ID)
        self.ladderMotion = state:GetMotionProcessor(LadderMotion.ID)
    end
end

function CharacterAnimator.Process(self: CharacterAnimator, state: MotionState.MotionState, delta: number)
    if self.character and self.animator then
        assert(self.horizontalMotion)
        assert(self.ladderMotion)

        local velocityFlat = state.velocity
        velocityFlat = Vector3.new(velocityFlat.x, 0, velocityFlat.z)

        self.animator:Set(WALK_SPEED, velocityFlat:Length() / self.horizontalMotion.options.movementSpeed)
        self.animator:Set(CLIMB_SPEED, if self.ladderMotion.isMoving then 1.0 else 0.0)

        for _, stateInfo in STATES do
            if not state:IsState(stateInfo.state) then
                continue
            end

            if self.state == stateInfo.state then
                return
            end

            self.state = stateInfo.state

            for key, value in stateInfo.properties do
                self.animator:Set(key, value)
            end

            return
        end

        self.animator:Set(TRANSITION_MAIN, MainTransition.BASE)
    end
end

export type CharacterAnimator = typeof(CharacterAnimator.new())
return CharacterAnimator
