local CameraController = require("scenes/character/CameraController")

local CharacterImpl = {}
local Character = gdclass("Character", "RigidBody3D")
    :RegisterImpl(CharacterImpl)

type WallInfo = {
    point: Vector3,
    normal: Vector3,
}

type CharacterT = {
    cameraPath: string,
    margin: number,
    maxGroundAngle: number,
    pushForce: number,

    cameraUpdated: Signal,

    camera: CameraController.CameraController?,
    cameraPathInternal: string,
    collider: CollisionShape3D,
    capsule: CapsuleShape3D,

    isGrounded: boolean,
    groundRid: RID,
    groundNormal: Vector3,
    groundOverride: {[string]: Vector3},

    velocity: Vector3,
    state: number,
    walls: {WallInfo},
    motionProcessors: {CharacterMotion},

    -- TODO: Luau 561: Type checking is messed up when this class is used externally unless these are forward declared
    IsStableGround: (self: Character, normal: Vector3) -> boolean,
    IsState: (self: Character, state: number) -> boolean,
    TestMotion: (self: Character, params: PhysicsTestMotionParameters3D, result: PhysicsTestMotionResult3D?) -> boolean,
}

export type Character = RigidBody3D & CharacterT & typeof(CharacterImpl)

CharacterImpl.CharacterState = {
    NONE = 0,
    IDLE = 1,
    JUMPING = 2,
    FALLING = 4,
    WALKING = 8,
    CLIMBING = 16,
}

-------------------
-- MotionContext --
-------------------

local MotionContext = {}
MotionContext.__index = MotionContext

function MotionContext.new(character: Character): MotionContext
    local self = {}

    -- Non changing
    self.character = character

    -- Input
    self.wasGrounded = false
    self.inputDirection = Vector3.ZERO
    self.camBasisFlat = Basis.IDENTITY

    -- State

    -- List of motion processor IDs which should be cancelled.
    -- Order of processing matters.
    self.cancelledProcessors = {} :: {[string]: boolean}

    -- States which don't really make sense to be applied
    -- (i.e. WALKING when CLIMBING)
    self.cancelledStates = 0

    -- Output
    self.newState = Character.CharacterState.NONE
    self.offset = Vector3.ZERO
    self.angularOffset = 0

    return setmetatable(self, MotionContext)
end

function MotionContext:SetState(state: number)
    self.newState = bit32.bor(self.newState, state)
end

function MotionContext:CancelProcessor(id: string)
    self.cancelledProcessors[id] = true
end

function MotionContext:CancelState(state: number)
    self.cancelledStates = bit32.bor(self.cancelledStates, state)
end

CharacterImpl.MotionContext = MotionContext
export type MotionContext = typeof(MotionContext.new(Character.new() :: Character))

---------------------
-- CharacterMotion --
---------------------

local CharacterMotion = { ID = "" }
CharacterMotion.__index = CharacterMotion

function CharacterMotion.new(): CharacterMotion
    local self = {}
    return setmetatable(self, CharacterMotion)
end

function CharacterMotion:HandleCancel(ctx: MotionContext)
end

function CharacterMotion:ProcessMotion(ctx: MotionContext, delta: number)
end

export type CharacterMotion = typeof(CharacterMotion.new())
CharacterImpl.CharacterMotion = CharacterMotion

---------------
-- Character --
---------------

Character:RegisterProperty("cameraPath", Enum.VariantType.NODE_PATH)
    :NodePath("Camera3D")
    :SetGet("setCameraPath", "getCameraPath")

Character:RegisterProperty("margin", Enum.VariantType.FLOAT)
    :Range(0, 1)
    :Default(0.001)

Character:RegisterProperty("maxGroundAngle", {
    type = Enum.VariantType.FLOAT,
    hint = Enum.PropertyHint.RANGE,
    hintString = "0,90,1,degrees"
})
    :Default(45)

Character:RegisterProperty("pushForce", Enum.VariantType.FLOAT)
    :Range(0, 100)
    :Default(70)

Character:RegisterSignal("cameraUpdated")
    :Args({ name = "camera", type = Enum.VariantType.OBJECT, className = "Camera3D" })

function CharacterImpl._Init(obj: RigidBody3D, tbl: CharacterT)
    tbl.camera = nil
    tbl.cameraPathInternal = ""

    tbl.isGrounded = false
    tbl.groundRid = RID.new()
    tbl.groundNormal = Vector3.ZERO
    tbl.groundOverride = {}

    tbl.velocity = Vector3.ZERO
    tbl.state = Character.CharacterState.IDLE
    tbl.walls = {}

    -- Defer loading to _Init to avoid cyclic dependency
    tbl.motionProcessors = {}

    local function addProcessor(file)
        table.insert(
            tbl.motionProcessors,
            (require(`scenes/character/motion/{file}.mod`) :: any).new()
        )
    end

    addProcessor("LadderMotion")
    addProcessor("HorizontalMotion")
    addProcessor("PhysicalMotion")
    addProcessor("StairsMotion")
    addProcessor("PlatformMotion")
end

function CharacterImpl.SetMode(self: Character, mode: ClassEnumPhysicsServer3D_BodyMode)
    PhysicsServer3D.GetSingleton():BodySetMode(self:GetRid(), mode)
end

function CharacterImpl.updateCamera(self: Character)
    if not self:IsInsideTree() then
        return
    end

    if self.camera then
        self.camera.focusNode = nil
    end

    if self.cameraPathInternal == "" then
        self.camera = nil
    else
        local camera = self:GetNode(self.cameraPathInternal) :: CameraController.CameraController
        camera.focusNode = self
        self.camera = camera

        self.cameraUpdated:Emit(camera)
    end
end

function CharacterImpl.setCameraPath(self: Character, path: string)
    self.cameraPathInternal = path
    self:updateCamera()
end

Character:RegisterMethod("setCameraPath")
    :Args({ name = "path", type = Enum.VariantType.NODE_PATH })

function CharacterImpl.getCameraPath(self: Character): string
    return self.cameraPathInternal
end

Character:RegisterMethod("getCameraPath")
    :ReturnVal({ type = Enum.VariantType.NODE_PATH })

function CharacterImpl._Ready(self: Character)
    self:SetMode(PhysicsServer3D.BodyMode.KINEMATIC)

    self.collider = self:GetNode("Capsule") :: CollisionShape3D
    self.capsule = self.collider.shape :: CapsuleShape3D

    self:updateCamera()
end

Character:RegisterMethod("_Ready")

function CharacterImpl.IsStableGround(self: Character, normal: Vector3): boolean
    local ANGLE_MARGIN = 0.01
    return normal:AngleTo(Vector3.UP) <= math.rad(self.maxGroundAngle) + ANGLE_MARGIN
end

function CharacterImpl.TestMotion(self: Character, params: PhysicsTestMotionParameters3D, result: PhysicsTestMotionResult3D?): boolean
    return PhysicsServer3D.GetSingleton():BodyTestMotion(self:GetRid(), params, result)
end

function CharacterImpl.checkGrounding(self: Character, snap: boolean)
    local GROUNDING_DISTANCE = 0.01

    for key, normal in self.groundOverride do
        if normal:LengthSquared() > 0 then
            self.isGrounded = true
            self.groundNormal = normal
            return
        end
    end

    local params = PhysicsTestMotionParameters3D.new()
    params.from = self.globalTransform
    params.motion = Vector3.DOWN * GROUNDING_DISTANCE
    params.recoveryAsCollision = true
    params.margin = self.margin
    params.maxCollisions = 4

    local result = PhysicsTestMotionResult3D.new()
    local didCollide = self:TestMotion(params, result)

    local foundGround = false

    if didCollide then
        for i = result:GetCollisionCount() - 1, 0, -1 do
            local normal = result:GetCollisionNormal(i)

            if self:IsStableGround(normal) then
                foundGround = true
                self.isGrounded = true
                self.groundRid = result:GetColliderRid(i)
                self.groundNormal = normal
            end
        end

        if foundGround and snap then
            -- dot to account for any possible horiz. movement due to depenetration
            local offset = Vector3.UP * Vector3.UP:Dot(result:GetTravel())
            if offset:Length() > self.margin then
                self.globalPosition = self.globalPosition + offset * (1 - self.margin)
            end
        end
    end

    if not foundGround then
        self.isGrounded = false
        self.groundNormal = Vector3.ZERO
    end
end

function shouldPush(rid: RID): boolean
    local mode = PhysicsServer3D.GetSingleton():BodyGetMode(rid)
    return mode == PhysicsServer3D.BodyMode.RIGID or mode == PhysicsServer3D.BodyMode.RIGID_LINEAR
end

function CharacterImpl.updateWalls(self: Character)
    table.clear(self.walls)

    local WALL_MARGIN = 0.1

    local wallParams = PhysicsTestMotionParameters3D.new()
    wallParams.from = self.globalTransform
    wallParams.motion = Vector3.ZERO
    wallParams.margin = WALL_MARGIN
    wallParams.recoveryAsCollision = true
    wallParams.maxCollisions = 4

    local wallResult = PhysicsTestMotionResult3D.new()
    self:TestMotion(wallParams, wallResult)

    for i = 0, wallResult:GetCollisionCount() - 1 do
        local normal = wallResult:GetCollisionNormal(i)
        if not self:IsStableGround(normal) and not shouldPush(wallResult:GetColliderRid(i)) then
            table.insert(self.walls, {
                point = wallResult:GetCollisionPoint(i),
                normal = wallResult:GetCollisionNormal(i)
            })
        end
    end
end

function CharacterImpl.move(self: Character, delta: number, offset: Vector3)
    local MAX_SLIDES = 5

    local origPos = self.globalPosition
    local slides = 0

    local remaining = offset

    while slides < MAX_SLIDES and remaining:LengthSquared() > 1e-3 do
        local result = self:MoveAndCollide(remaining, false, self.margin)
        if result then
            local normal = result:GetNormal()
            local rid = result:GetColliderRid()

            if shouldPush(rid) then
                -- TODO: If moving faster than a certain velocity (i.e. related to movement velocity),
                -- apply traditional collision resolution (impulse, etc.)
                -- https://www.euclideanspace.com/physics/dynamics/collision/threed/index.htm

                local bodyState = assert(PhysicsServer3D.GetSingleton():BodyGetDirectState(rid))

                bodyState:ApplyForce(
                    remaining:Normalized() * self.pushForce,
                    result:GetPosition() - bodyState.transform.origin
                )
            end

            remaining = result:GetRemainder():Slide(normal)
        else
            break
        end

        slides += 1
    end

    self.velocity = (self.globalPosition - origPos) / delta
end

function CharacterImpl.IsState(self: Character, state: number): boolean
    return bit32.band(self.state, state) ~= 0
end

function CharacterImpl._PhysicsProcess(self: Character, delta: number)
    if self.camera then
        local ctx = MotionContext.new(self)
        ctx.wasGrounded = self.isGrounded

        local inputDirection2 = Input.GetSingleton():GetVector("move_left", "move_right", "move_forward", "move_backward")
        ctx.inputDirection = Vector3.new(inputDirection2.x, 0, inputDirection2.y)
        ctx.camBasisFlat = Basis.IDENTITY:Rotated(Vector3.UP, self.camera.cameraRotation.y)

        self:checkGrounding(not self:IsState(Character.CharacterState.JUMPING))

        for _, processor in self.motionProcessors do
            if ctx.cancelledProcessors[processor.ID] then
                processor:HandleCancel(ctx)
            else
                processor:ProcessMotion(ctx, delta)
            end
        end

        self:move(delta, ctx.offset)
        self:RotateY(ctx.angularOffset)

        self:updateWalls()

        if ctx.newState == Character.CharacterState.NONE then
            self.state = Character.CharacterState.IDLE
        else
            self.state = bit32.band(
                ctx.newState,
                bit32.bnot(ctx.cancelledStates)
            )
        end
    end
end

Character:RegisterMethodAST("_PhysicsProcess")

function CharacterImpl.GetMotionProcessor(self: Character, id: string): any
    for _, motion in self.motionProcessors do
        if motion.ID == id then
            return motion
        end
    end

    return nil
end

return Character
