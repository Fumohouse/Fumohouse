local Character = require("scenes/character/Character")
local HorizontalMotion = require("scenes/character/motion/HorizontalMotion.mod")
local PhysicalMotion = require("scenes/character/motion/PhysicalMotion.mod")
local StairsMotion = require("scenes/character/motion/StairsMotion.mod")
local DebugMenu = require("scenes/debug_menu/DebugMenu")
local DebugDraw = require("singletons/DebugDraw")

local DebugCharacterImpl = {}
local DebugCharacter = gdclass(nil, "../debug_menu/DebugMenu.lua")
    :RegisterImpl(DebugCharacterImpl)

type DebugCharacterT = {
    characterPath: string,

    character: Character.Character?,
    horizontalMotion: HorizontalMotion.HorizontalMotion?,
    physicalMotion: PhysicalMotion.PhysicalMotion?,
    stairsMotion: StairsMotion.StairsMotion?,

    state: RichTextLabel?,
}

export type DebugCharacter = DebugMenu.DebugMenu & DebugCharacterT & typeof(DebugCharacterImpl)

DebugCharacter:RegisterProperty("characterPath", Enum.VariantType.NODE_PATH)
    :NodePath("RigidBody3D")

function DebugCharacterImpl._Init(obj: PanelContainer, tbl: DebugMenu.DebugMenuT & DebugCharacterT)
    tbl.menuName = "character_debug"
    tbl.action = "debug_2"
end

function DebugCharacterImpl._Ready(self: DebugCharacter)
    DebugMenu._Ready(self)

    if self.characterPath ~= "" then
        local character = self:GetNode(self.characterPath) :: Character.Character

        self.horizontalMotion = character:GetMotionProcessor(HorizontalMotion.ID)
        self.physicalMotion = character:GetMotionProcessor(PhysicalMotion.ID)
        self.stairsMotion = character:GetMotionProcessor(StairsMotion.ID)

        self.character = character
    end

    self.state = self:AddEntry("state", "State").contents

    self:AddEntry("grounded", "Is Grounded")
    self:AddEntry("airborne", "Airborne Time")
    self:AddEntry("speed", "Speed")
    self:AddEntry("walls", "Wall Contacts")
end

function DebugCharacterImpl.debugDraw(self: DebugCharacter)
    assert(self.character)
    local pos = self.character.globalPosition
    local eyePos = pos + Vector3.UP * assert(self.character.camera).cameraOffset

    local DebugDraw = _G["DebugDraw"] :: DebugDraw.DebugDraw

    -- Forward direction
    DebugDraw:DrawLine(eyePos, eyePos - self.character.globalTransform.basis.z, Color.AQUA)

    -- Grounding status
    if self.character.isGrounded then
        DebugDraw:DrawLine(pos, pos + self.character.groundNormal, Color.GREEN)
    else
        DebugDraw:DrawMarker(pos, Color.RED)
    end

    -- Walls
    for _, wallInfo in self.character.walls do
        DebugDraw:DrawLine(wallInfo.point, wallInfo.point + wallInfo.normal, Color.WHITE)
    end

    -- Velocities
    if self.horizontalMotion then
        local topSpeed = self.horizontalMotion.options.movementSpeed
        DebugDraw:DrawLine(pos, pos + self.character.velocity / topSpeed, Color.BLUE)
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

local STATES = {}
for name: string, value: number in pairs(Character.CharacterState) do
    table.insert(STATES, {
        name = name,
        value = value
    })
end

table.sort(STATES, function(a, b)
    return a.value < b.value
end)

function DebugCharacterImpl._Process(self: DebugCharacter, _delta: number)
    assert(self.character)
    assert(self.state)
    self.state:Clear()

    -- State
    for i, enumVal in STATES do
        if enumVal.value == Character.CharacterState.NONE then
            continue
        end

        self.state:PushColor(if self.character:IsState(enumVal.value) then Color.GREEN else Color.RED)
        self.state:AppendText(enumVal.name)
        self.state:Pop()

        if i ~= #STATES then
            self.state:Newline()
        end
    end

    -- Other
    self:SetVal("grounded", if self.character.isGrounded then "Yes" else "No")
    self:SetVal("airborne", if self.physicalMotion then string.format("%.3f sec", self.physicalMotion.airborneTime) else "???")

    local speedStr = string.format([[Total: %.3f m/s
HorizontalMotion: %.3f m/s
PhysicalMotion: %.3f m/s]],
        self.character.velocity:Length(),
        if self.horizontalMotion then self.horizontalMotion.velocity:Length() else 0,
        if self.physicalMotion then self.physicalMotion.velocity:Length() else 0)

    self:SetVal("speed", speedStr)
    self:SetVal("walls", tostring(#self.character.walls))

    self:debugDraw()
end

DebugCharacter:RegisterMethodAST("_Process")

return DebugCharacter
