local Utils = require("../../utils/Utils.mod")
local Character = require("../../character/Character")
local MotionState = require("../../character/MotionState.mod")
local HorizontalMotion = require("../../character/processors/HorizontalMotion.mod")
local PhysicalMotion = require("../../character/processors/PhysicalMotion.mod")
local StairsMotion = require("../../character/processors/StairsMotion.mod")
local DebugWindow = require("DebugWindow")
local InfoTable = require("InfoTable")

local DebugDrawM = require("../../utils/DebugDraw")
local DebugDraw = gdglobal("DebugDraw") :: DebugDrawM.DebugDraw

local DebugCharacterImpl = {}
local DebugCharacter = gdclass(nil, DebugWindow)
    :RegisterImpl(DebugCharacterImpl)

export type DebugCharacter = DebugWindow.DebugWindow & typeof(DebugCharacterImpl) & {
    characterPathInternal: string,
    characterPath: string,

    character: Character.Character?,
    horizontalMotion: HorizontalMotion.HorizontalMotion?,
    physicalMotion: PhysicalMotion.PhysicalMotion?,
    stairsMotion: StairsMotion.StairsMotion?,

    infoTbl: InfoTable.InfoTable,
    state: RichTextLabel,
}

DebugCharacter:RegisterProperty("characterPath", Enum.VariantType.NODE_PATH)
    :NodePath(RigidBody3D)
    :SetGet("setCharacterPath", "getCharacterPath")

function DebugCharacterImpl._Init(self: DebugCharacter)
    self.action = "debug_2"
end

function DebugCharacterImpl.updateCharacter(self: DebugCharacter)
    if self:IsInsideTree() and self.characterPathInternal ~= "" then
        local character = self:GetNode(self.characterPath) :: Character.Character

        self.horizontalMotion = character.state:GetMotionProcessor(HorizontalMotion.ID)
        self.physicalMotion = character.state:GetMotionProcessor(PhysicalMotion.ID)
        self.stairsMotion = character.state:GetMotionProcessor(StairsMotion.ID)

        self.character = character
    end
end

function DebugCharacterImpl.setCharacterPath(self: DebugCharacter, path: string)
    self.characterPathInternal = path
    self:updateCharacter()
end

DebugCharacter:RegisterMethod("setCharacterPath")
    :Args({ name = "path", type = Enum.VariantType.NODE_PATH })

function DebugCharacterImpl.getCharacterPath(self: DebugCharacter)
    return self.characterPathInternal
end

DebugCharacter:RegisterMethod("getCharacterPath")
    :ReturnVal({ type = Enum.VariantType.NODE_PATH })

function DebugCharacterImpl._Ready(self: DebugCharacter)
    DebugWindow._Ready(self)
    self:SetWindowVisible(false)

    local infoTbl = self:GetNode("%InfoTable") :: InfoTable.InfoTable
    self.infoTbl = infoTbl

    self.state = infoTbl:AddEntry("state", "State").contents

    infoTbl:AddEntry("ragdoll", "Is Ragdoll")
    infoTbl:AddEntry("grounded", "Is Grounded")
    infoTbl:AddEntry("airborne", "Airborne Time")
    infoTbl:AddEntry("speed", "Speed")
    infoTbl:AddEntry("walls", "Wall Contacts")

    self:updateCharacter()
end

function DebugCharacterImpl.debugDraw(self: DebugCharacter)
    if self.character then
        local characterState = self.character.state
        local pos = self.character.globalPosition
        local eyePos = pos + Vector3.UP * assert(self.character.state.camera).cameraOffset

        -- Bottom point
        DebugDraw:DrawMarker(characterState:GetBottomPosition(), Color.WHITE)

        -- Forward direction
        DebugDraw:DrawLine(eyePos, eyePos - self.character.globalTransform.basis.z, Color.AQUA)

        -- Grounding status
        if self.character.state.isGrounded then
            DebugDraw:DrawLine(pos, pos + characterState.groundNormal, Color.GREEN)
        else
            DebugDraw:DrawMarker(pos, Color.RED)
        end

        -- Walls
        for _, wallInfo in characterState.walls do
            DebugDraw:DrawLine(wallInfo.point, wallInfo.point + wallInfo.normal, Color.WHITE)
        end

        -- Velocities
        if self.horizontalMotion then
            local velocityScale = self.horizontalMotion.options.walkSpeed
            DebugDraw:DrawLine(pos, pos + characterState.velocity / velocityScale, Color.BLUE)
        end

        -- Stairs
        if self.stairsMotion and self.stairsMotion.foundStair then
            local STAIRS_AXIS_LEN = 0.25

            local target = self.stairsMotion.endPosition

            DebugDraw:DrawMarker(self.stairsMotion.beginPosition, Color.AQUA)
            DebugDraw:DrawMarker(target, Color.AQUA)

            DebugDraw:DrawLine(
                target, target + self.stairsMotion.wallTangent * STAIRS_AXIS_LEN, Color.RED
            )

            DebugDraw:DrawLine(
                target, target + self.stairsMotion.slopeNormal * STAIRS_AXIS_LEN, Color.GREEN
            )

            DebugDraw:DrawLine(
                target, target + self.stairsMotion.motionVector * STAIRS_AXIS_LEN, Color.BLUE
            )
        end
    end
end

local STATES = {}
for name: string, value: number in pairs(MotionState.CharacterState) do
    table.insert(STATES, {
        name = name,
        value = value
    })
end

table.sort(STATES, function(a, b)
    return a.value < b.value
end)

function DebugCharacterImpl._Process(self: DebugCharacter, delta: number)
    assert(self.character)

    local characterState = self.character.state

    self.state:Clear()

    -- State
    for i, enumVal in STATES do
        if enumVal.value == MotionState.CharacterState.NONE then
            continue
        end

        self.state:PushColor(if characterState:IsState(enumVal.value) then Color.GREEN else Color.RED)
        self.state:AppendText(enumVal.name)
        self.state:Pop()

        if i ~= #STATES then
            self.state:Newline()
        end
    end

    -- Other
    local infoTbl = self.infoTbl

    infoTbl:SetVal("ragdoll", if characterState.isRagdoll then "Yes" else "No")
    infoTbl:SetVal("grounded", if characterState.isGrounded then "Yes" else "No")
    infoTbl:SetVal("airborne", if self.physicalMotion then string.format("%.3f sec", self.physicalMotion.airborneTime) else "???")

    local speedStr = `Total: {Utils.FormatVector3(characterState.velocity)} m/s`

    for _, processor in characterState.motionProcessors do
        local velocity = processor:GetVelocity()

        if velocity then
            speedStr ..= `\n{processor.ID}: {Utils.FormatVector3(velocity)} m/s`
        end
    end

    infoTbl:SetVal("speed", speedStr)
    infoTbl:SetVal("walls", tostring(#characterState.walls))

    self:debugDraw()
end

DebugCharacter:RegisterMethodAST("_Process")

return DebugCharacter
