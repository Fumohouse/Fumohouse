local ConfigOptionButton = require("ConfigOptionButton")

local ConfigAudioOutputDevicesImpl = {}
local ConfigAudioOutputDevices = gdclass(nil, ConfigOptionButton)
    :Permissions(Enum.Permissions.INTERNAL)
    :RegisterImpl(ConfigAudioOutputDevicesImpl)

export type ConfigAudioOutputDevices = ConfigOptionButton.ConfigOptionButton & typeof(ConfigAudioOutputDevicesImpl) & {
    devices: PackedStringArray,
}

function ConfigAudioOutputDevicesImpl._SetValue(self: ConfigAudioOutputDevices, value: string)
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

function ConfigAudioOutputDevicesImpl._GetValue(self: ConfigAudioOutputDevices): Variant
    return self.devices:Get(self.input.selected + 1)
end

function ConfigAudioOutputDevicesImpl._Ready(self: ConfigAudioOutputDevices)
    self.devices = AudioServer.singleton:GetOutputDeviceList()
    ConfigOptionButton._Ready(self)
end

return ConfigAudioOutputDevices
