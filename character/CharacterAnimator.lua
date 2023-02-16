local Character = require("Character")
local HorizontalMotion = require("motion/HorizontalMotion.mod")
local LadderMotion = require("motion/LadderMotion.mod")

local CharacterAnimatorImpl = {}
local CharacterAnimator = gdclass(nil, "Node")
    :RegisterImpl(CharacterAnimatorImpl)

type CharacterAnimatorT = {
    character: Character.Character,
    animator: AnimationTree,

    horizontalMotion: HorizontalMotion.HorizontalMotion,
    ladderMotion: LadderMotion.LadderMotion,

    state: number,
}

export type CharacterAnimator = Node & CharacterAnimatorT & typeof(CharacterAnimatorImpl)

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
        state = Character.CharacterState.CLIMBING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.VERTICAL,
            [TRANSITION_VERTICAL] = VerticalTransition.CLIMB,
            [JUMP] = AnimationNodeOneShot.OneShotRequest.NONE,
        }
    },
    {
        state = Character.CharacterState.FALLING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.VERTICAL,
            [TRANSITION_VERTICAL] = VerticalTransition.FALL,
            [JUMP] = AnimationNodeOneShot.OneShotRequest.NONE,
        }
    },
    {
        state = Character.CharacterState.JUMPING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.VERTICAL,
            [TRANSITION_VERTICAL] = VerticalTransition.FALL,
            [JUMP] = AnimationNodeOneShot.OneShotRequest.FIRE,
        }
    },
    {
        state = Character.CharacterState.WALKING,
        properties = {
            [TRANSITION_MAIN] = MainTransition.HORIZONTAL,
        }
    },
    {
        state = Character.CharacterState.IDLE,
        properties = {
            [TRANSITION_MAIN] = MainTransition.IDLE,
        }
    }
}

function CharacterAnimatorImpl._Init(obj: Node, tbl: CharacterAnimatorT)
    tbl.state = Character.CharacterState.NONE
end

function CharacterAnimatorImpl._Ready(self: CharacterAnimator)
    self.character = self:GetParent() :: Character.Character

    self.horizontalMotion = self.character:GetMotionProcessor(HorizontalMotion.ID)
    self.ladderMotion = self.character:GetMotionProcessor(LadderMotion.ID)

    self.animator = self:GetNode("../Rig/Armature/AnimationTree") :: AnimationTree
end

CharacterAnimator:RegisterMethod("_Ready")

function CharacterAnimatorImpl._PhysicsProcess(self: CharacterAnimator, delta: number)
    local velocityFlat = self.character.velocity
    velocityFlat = Vector3.new(velocityFlat.x, 0, velocityFlat.z)

    self.animator:Set(WALK_SPEED, velocityFlat:Length() / self.horizontalMotion.options.movementSpeed)
    self.animator:Set(CLIMB_SPEED, if self.ladderMotion.isMoving then 1.0 else 0.0)

    for _, state in STATES do
        if not self.character:IsState(state.state) then
            continue
        end

        if self.state == state.state then
            break
        end

        self.state = state.state

        for key, value in state.properties do
            self.animator:Set(key, value)
        end

        break
    end
end

CharacterAnimator:RegisterMethodAST("_PhysicsProcess")

return CharacterAnimator
