local ConfigBoundControl = require("ConfigBoundControl")

local ConfigActionBindImpl = {}
local ConfigActionBind = gdclass(nil, ConfigBoundControl)
    :RegisterImpl(ConfigActionBindImpl)

export type ConfigActionBind = ConfigBoundControl.ConfigBoundControl & typeof(ConfigActionBindImpl) & {
    input: Button,
    event: InputEvent,
}

function ConfigActionBindImpl._SetValue(self: ConfigActionBind, value: InputEvent)
    self.event = value
end

function ConfigActionBindImpl._GetValue(self: ConfigActionBind): Variant
    return self.event
end

function ConfigActionBindImpl._Input(self: ConfigActionBind, event: InputEvent)
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

ConfigActionBind:RegisterMethodAST("_Input")

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

function ConfigActionBindImpl._OnToggled(self: ConfigActionBind, isPressed: boolean)
    if isPressed then
        self.input.text = "Waiting for input..."
    else
        self.input.text = displayEvent(self.event)
    end
end

ConfigActionBind:RegisterMethodAST("_OnToggled")

function ConfigActionBindImpl._Ready(self: ConfigActionBind)
    ConfigBoundControl._Ready(self)

    self:_OnToggled(self.input.buttonPressed)
    self.input.toggled:Connect(Callable.new(self, "_OnToggled"))
end

return ConfigActionBind
