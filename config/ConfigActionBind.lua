local ConfigBoundControl = require("ConfigBoundControl")

--- @class
--- @extends ConfigBoundControl
local ConfigActionBind = {}
local ConfigActionBindC = gdclass(ConfigActionBind)

--- @classType ConfigActionBind
export type ConfigActionBind = ConfigBoundControl.ConfigBoundControl & typeof(ConfigActionBind) & {
    input: Button,
    event: InputEvent,
}

local function displayEvent(event: InputEvent)
    if event:IsA(InputEventKey) then
        local ek = event :: InputEventKey
        return ek:AsTextPhysicalKeycode()
    elseif event:IsA(InputEventMouseButton) then
        local emb = event :: InputEventMouseButton
        return emb:AsText()
    end

    return "???"
end

function ConfigActionBind._SetValue(self: ConfigActionBind, value: InputEvent)
    self.event = value
    self.input.text = displayEvent(self.event)
end

function ConfigActionBind._GetValue(self: ConfigActionBind): Variant
    return self.event
end

function ConfigActionBind._ApproxEqual(self: ConfigActionBind, a: any, b: any)
    if typeof(a) == "InputEventKey" and typeof(b) == "InputEventKey" then
        local eka = a :: InputEventKey
        local ekb = b :: InputEventKey

        local keycodeA = if eka.keycode == 0 then eka.physicalKeycode else eka.keycode
        local keycodeB = if ekb.keycode == 0 then ekb.physicalKeycode else ekb.keycode

        return keycodeA == keycodeB and eka:GetModifiersMask() == ekb:GetModifiersMask()
    end

    return ConfigBoundControl._ApproxEqual(self, a, b)
end

--- @registerMethod
function ConfigActionBind._Input(self: ConfigActionBind, event: InputEvent)
    if not self.input.buttonPressed or event:IsPressed() then
        return
    end

    local handleEvent = false

    if event:IsA(InputEventKey) then
        handleEvent = true
    elseif event:IsA(InputEventMouseButton) then
        local emb = event :: InputEventMouseButton
        if emb.buttonIndex == Enum.MouseButton.LEFT and
                Rect2.new(Vector2.ZERO, self.input.size):HasPoint(self.input:GetLocalMousePosition()) then
            return
        end

        handleEvent = true
    end

    if handleEvent then
        self.event = event
        self:UpdateConfigValue()
        self:GetViewport():SetInputAsHandled()
        self.input.buttonPressed = false
    end
end

--- @registerMethod
function ConfigActionBind._OnToggled(self: ConfigActionBind, isPressed: boolean)
    if isPressed then
        self.input.text = "Waiting for input..."
    else
        self.input.text = displayEvent(self.event)
    end

    -- Prevent options menu from being dismissed due to pressing menu_back
    -- Two frames because... yeah.
    for i = 1, 2 do
        wait_signal(self:GetTree().processFrame)
    end

    self.input:SetMeta("blockDismiss", isPressed)
end

function ConfigActionBind._Ready(self: ConfigActionBind)
    ConfigBoundControl._Ready(self)

    self:_OnToggled(self.input.buttonPressed)
    self.input.toggled:Connect(Callable.new(self, "_OnToggled"))
end

return ConfigActionBindC
