local ConfigOptionButton = require("ConfigOptionButton")

--- @class
--- @extends ConfigOptionButton
--- @permissions INTERNAL
local ConfigAudioOutputDevices = {}
local ConfigAudioOutputDevicesC = gdclass(ConfigAudioOutputDevices)

--- @classType ConfigAudioOutputDevices
export type ConfigAudioOutputDevices = ConfigOptionButton.ConfigOptionButton & typeof(ConfigAudioOutputDevices) & {
    devices: PackedStringArray,
}

function ConfigAudioOutputDevices._SetValue(self: ConfigAudioOutputDevices, value: string)
    -- Initialize here due to super _Ready. Kinda hacky
    if self.input.itemCount == 0 then
        for _, device: string in self.devices do
            self.input:AddItem(device)
        end
    end

    local deviceIdx = self.devices:Find(value)
    if deviceIdx >= 0 then
        self.input:Select(deviceIdx)
    else
        self.input:AddItem(value)
        self.input:Select(self.input.itemCount - 1)
    end
end

function ConfigAudioOutputDevices._GetValue(self: ConfigAudioOutputDevices): Variant
    return self.devices:Get(self.input.selected)
end

function ConfigAudioOutputDevices._Ready(self: ConfigAudioOutputDevices)
    self.devices = AudioServer.singleton:GetOutputDeviceList()
    ConfigOptionButton._Ready(self)
end

return ConfigAudioOutputDevicesC
