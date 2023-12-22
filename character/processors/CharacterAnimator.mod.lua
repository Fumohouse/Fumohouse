--[[
    Updates animations on a Character.
]]

local Character = require("../Character")
local AppearanceManager = require("../appearance/AppearanceManager")
local HorizontalMotion = require("HorizontalMotion.mod")
local LadderMotion = require("LadderMotion.mod")
local MotionState = require("../MotionState.mod")

local CharacterAnimator = { ID = "animator" }
CharacterAnimator.__index = CharacterAnimator

local MainTransition = {
    BASE = "base",
    IDLE = "idle",
    SIT = "sit",
    HORIZONTAL = "horizontal",
    VERTICAL = "vertical",
    SWIM = "swim",
    DEAD = "dead",
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

local DeadTransition = {
    IDLE = "idle",
    DEATH1 = "death1",
}

local WALK_SPEED = "parameters/walk_speed/scale"
local RUN_SPEED = "parameters/run_speed/scale"
local CLIMB_SPEED = "parameters/climb_speed/scale"
local SWIM_SPEED = "parameters/swim_speed/scale"

local TRANSITION_MAIN = "parameters/main/transition_request"
local TRANSITION_VERTICAL = "parameters/vertical/transition_request"
local TRANSITION_HORIZONTAL = "parameters/horizontal/transition_request"
local TRANSITION_SWIMMING = "parameters/swimming/transition_request"
local TRANSITION_DEAD = "parameters/dead/transition_request"

local JUMP = "parameters/jump_oneshot/request"

type StateInfo = {
    state: number,
    properties: {[string]: any},
    init: (self: CharacterAnimator, state: MotionState.MotionState, animator: AnimationTree) -> ()?,
    update: (self: CharacterAnimator, state: MotionState.MotionState, animator: AnimationTree, delta: number) -> ()?,
}

local function updateDeathAnimation(state: MotionState.MotionState, animator: AnimationTree)
    if state:IsState(MotionState.CharacterState.FALLING) then
        animator:Set(TRANSITION_DEAD, DeadTransition.IDLE)
    else
        animator:Set(TRANSITION_DEAD, DeadTransition.DEATH1)
        return 1.5
    end

    return 0
end

local STATES: {StateInfo} = {
    {
        state = MotionState.CharacterState.DEAD,
        properties = {
            [TRANSITION_MAIN] = MainTransition.DEAD,
        },
        init = function(self, state, animator)
            assert(self.appearanceManager)

            local flakeDelay = updateDeathAnimation(state, animator)

            coroutine.wrap(function()
                wait(flakeDelay)

                -- TODO: awful type hacks to avoid weird errors
                local particles = (self.character :: Character.Character):GetNode("%DeathParticles") :: GPUParticles3D
                particles.emitting = true

                local tween = (self.appearanceManager :: AppearanceManager.AppearanceManager):GetTree():CreateTween()
                tween:TweenMethod(Callable.new(self.appearanceManager :: AppearanceManager.AppearanceManager, "SetDissolve"), tofloat(1e-10), 1.0, 2.0)
            end)()
        end,
        update = function(self, state, animator)
            updateDeathAnimation(state, animator)
        end,
    },
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
        update = function(self, state, animator, delta)
            assert(self.horizontalMotion)

            local velocityFlat = state.velocity
            velocityFlat = Vector3.new(velocityFlat.x, 0, velocityFlat.z)
            local horizSpeed = velocityFlat:Length()

            local SPEED_THRESHOLD = 0.2

            -- TODO: Luau 567: type hacks below
            -- Prevent jittery switching between animations (e.g. on stairs)
            if horizSpeed > self.horizontalMotion.options.walkSpeed :: number + SPEED_THRESHOLD then
                self.runningTime = self.runningTime :: number + delta
            else
                self.runningTime = 0
            end

            if self.runningTime > self.options.minRunningTime then
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
    self.appearanceManager = nil :: AppearanceManager.AppearanceManager?
    self.horizontalMotion = nil :: HorizontalMotion.HorizontalMotion?
    self.ladderMotion = nil :: LadderMotion.LadderMotion?

    self.state = nil :: StateInfo?

    self.runningTime = 0

    self.options = {
        minRunningTime = 0.15,
    }

    return setmetatable(self, CharacterAnimator)
end

function CharacterAnimator.Initialize(self: CharacterAnimator, state: MotionState.MotionState)
    if not state.node:IsA(Character) then
        return
    end

    self.character = state.node :: Character.Character
    self.animator = state.node:GetNodeOrNull("Rig/Armature/AnimationTree") :: AnimationTree?
    self.appearanceManager = state.node:GetNodeOrNull("Appearance") :: AppearanceManager.AppearanceManager?

    if self.animator then
        self.animator.active = true
    end

    self.horizontalMotion = state:GetMotionProcessor(HorizontalMotion.ID)
    self.ladderMotion = state:GetMotionProcessor(LadderMotion.ID)
end

function CharacterAnimator.Process(self: CharacterAnimator, state: MotionState.MotionState, delta: number)
    if state.ctx.isReplay or not self.character or not self.animator then
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

        if stateInfo.init then
            stateInfo.init(self, state, self.animator)
        end

        for key, value in stateInfo.properties do
            self.animator:Set(key, value)
        end

        break
    end

    if self.state and self.state.update then
        self.state.update(self, state, self.animator, delta)
    end
end

export type CharacterAnimator = typeof(CharacterAnimator.new())
return CharacterAnimator
