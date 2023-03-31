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
    SWIM = "swim",
}

local VerticalTransition = {
    FALL = "fall",
    CLIMB = "climb",
}

local HorizontalTransition = {
    WALK = "walk",
    RUN = "run",
}

local SwimmingTransition = {
    IDLE = "idle",
    SWIM = "swim",
}

local WALK_SPEED = "parameters/walk_speed/scale"
local RUN_SPEED = "parameters/run_speed/scale"
local CLIMB_SPEED = "parameters/climb_speed/scale"
local SWIM_SPEED = "parameters/swim_speed/scale"

local TRANSITION_MAIN = "parameters/main/transition_request"
local TRANSITION_VERTICAL = "parameters/vertical/transition_request"
local TRANSITION_HORIZONTAL = "parameters/horizontal/transition_request"
local TRANSITION_SWIMMING = "parameters/swimming/transition_request"

local JUMP = "parameters/jump_oneshot/request"

type StateInfo = {
    state: number,
    properties: {[string]: any},
    update: (self: CharacterAnimator, state: MotionState.MotionState, animator: AnimationTree) -> ()?,
}

local STATES: {StateInfo} = {
    {
        state = bit32.bor(MotionState.CharacterState.SWIMMING, MotionState.CharacterState.IDLE),
        properties = {
            [TRANSITION_MAIN] = MainTransition.SWIM,
            [TRANSITION_SWIMMING] = SwimmingTransition.IDLE,
        }
    },
    {
        state = MotionState.CharacterState.SWIMMING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.SWIM,
            [TRANSITION_SWIMMING] = SwimmingTransition.SWIM,
        },
        update = function(self, state, animator)
            assert(self.horizontalMotion)
            -- TODO: Luau 568: type hack below
            animator:Set(SWIM_SPEED, (state.velocity :: Vector3):Length() / self.horizontalMotion.options.walkSpeed)
        end
    },
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
        },
        update = function(self, state, animator)
            assert(self.ladderMotion)
            animator:Set(CLIMB_SPEED, if self.ladderMotion.isMoving then 1.0 else 0.0)
        end
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
        },
        update = function(self, state, animator)
            assert(self.horizontalMotion)

            local velocityFlat = state.velocity
            velocityFlat = Vector3.new(velocityFlat.x, 0, velocityFlat.z)
            local horizSpeed = velocityFlat:Length()

            local SPEED_THRESHOLD = 0.2

            -- TODO: Luau 567: type hack below
            if horizSpeed > self.horizontalMotion.options.walkSpeed :: number + SPEED_THRESHOLD then
                animator:Set(TRANSITION_HORIZONTAL, HorizontalTransition.RUN)
                animator:Set(RUN_SPEED, horizSpeed / self.horizontalMotion.options.runSpeed)
            else
                animator:Set(TRANSITION_HORIZONTAL, HorizontalTransition.WALK)
                animator:Set(WALK_SPEED, horizSpeed / self.horizontalMotion.options.walkSpeed)
            end
        end
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

    self.state = nil :: StateInfo?

    return setmetatable(self, CharacterAnimator)
end

function CharacterAnimator.Initialize(self: CharacterAnimator, state: MotionState.MotionState)
    if not state.node:IsA(Character) then
        return
    end

    self.character = state.node :: Character.Character
    self.animator = state.node:GetNodeOrNull("Rig/Armature/AnimationTree") :: AnimationTree?

    if self.animator then
        self.animator.active = true
    end

    self.horizontalMotion = state:GetMotionProcessor(HorizontalMotion.ID)
    self.ladderMotion = state:GetMotionProcessor(LadderMotion.ID)
end

function CharacterAnimator.Process(self: CharacterAnimator, state: MotionState.MotionState, delta: number)
    if not self.character or not self.animator then
        return
    end

    for _, stateInfo in STATES do
        if not state:IsState(stateInfo.state) then
            continue
        end

        if self.state == stateInfo then
            break
        end

        self.state = stateInfo

        for key, value in stateInfo.properties do
            self.animator:Set(key, value)
        end

        break
    end

    if self.state and self.state.update then
        self.state.update(self, state, self.animator)
    end
end

export type CharacterAnimator = typeof(CharacterAnimator.new())
return CharacterAnimator
