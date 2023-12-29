--- @class
--- @extends Control
local ViewportInput = {}
local ViewportInputC = gdclass(ViewportInput)

--- @classType ViewportInput
export type ViewportInput = Control & typeof(ViewportInput) & {
    --- @property
    --- @default true
    enabled: boolean,

    --- @property
    viewport: SubViewport,
}

--- @registerMethod
function ViewportInput._GuiInput(self: ViewportInput, event: InputEvent)
    if not self.enabled then
        return
    end

    local actualEvent = event:Duplicate()

    local scale = Vector2.new(self.viewport.size) / self.size

    if actualEvent:IsA(InputEventMouse) then
        local em = actualEvent :: InputEventMouse
        em.position *= scale
    end

    if actualEvent:IsA(InputEventMouseMotion) then
        local emm = actualEvent :: InputEventMouseMotion
        emm.relative *= scale
    end

    self.viewport:PushInput(actualEvent, true)
    self:AcceptEvent()
end

return ViewportInputC
