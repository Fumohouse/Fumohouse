local DebugMenu = require("scenes/debug_menu/DebugMenu")
local Utils = require("scripts/Utils.mod")

local DebugInfoImpl = {}
local DebugInfo = gdclass(nil, "DebugMenu.lua")
    :Permissions(bit32.bor(Enum.Permissions.INTERNAL, Enum.Permissions.OS))
    :RegisterImpl(DebugInfoImpl)

type DebugInfoT = {
    egg: number,
    otherEntries: {DebugMenu.DebugMenuEntry},
    otherVisible: boolean,
}

export type DebugInfo = DebugMenu.DebugMenu & DebugInfoT & typeof(DebugInfoImpl)

local EFFECTS = {
    { "", "" },
    { "[rainbow freq=0.2 sat=1 val=1]", "[/rainbow]" },
    { "[wave amp=50 freq=2]", "[/wave]" },
    { "[tornado radius=8 freq=5]", "[/tornado]" },
    { "[shake rate=20 level=10]", "[/shake]" },
}

local DRIVERS = {
    ["forward_plus"] = "Vulkan",
    ["mobile"] = "Vulkan Mobile",
    ["gl_compatibility"] = "GLES 3",
}

function DebugInfoImpl._Init(obj: PanelContainer, tbl: DebugMenu.DebugMenuT & DebugInfoT)
    tbl.menuName = "debug_info"
    tbl.menuVisible = true

    tbl.egg = 1
    tbl.otherEntries = {}
    tbl.otherVisible = false
end

function DebugInfoImpl.updateEgg(self: DebugInfo)
    local ICON = "[img=32x32]res://assets/textures/logo_dark.png[/img]"

    local effect = EFFECTS[self.egg]
    self:SetVal("build", `{ICON} [b]Fumohouse[/b] {effect[1]}[url=egg]{Utils.GetBuildString()}[/url]{effect[2]}`)
end

function DebugInfoImpl._OnMetaClicked(self: DebugInfo, meta: Variant)
    if meta == "egg" then
        self.egg += 1
        if self.egg == #EFFECTS + 1 then
            self.egg = 1
        end

        self:updateEgg()
    end
end

DebugInfo:RegisterMethodAST("_OnMetaClicked")

function DebugInfoImpl.addOtherEntry(self: DebugInfo, id: string, label: string?)
    table.insert(self.otherEntries, self:AddEntry(id, label))
end

function DebugInfoImpl.setOtherVisible(self: DebugInfo, visible: boolean)
    for _, item in self.otherEntries do
        item.root.visible = visible
    end

    self.otherVisible = visible
end

function DebugInfoImpl._Ready(self: DebugInfo)
    DebugMenu._Ready(self)

    local contents = self:AddEntry("build").contents
    contents.metaClicked:Connect(Callable.new(self, "_OnMetaClicked"))
    contents.metaUnderlined = false

    self:updateEgg()

    local verInfo = Engine.GetSingleton():GetVersionInfo()
    local major, minor, patch, status, build, hash =
        verInfo:Get("major") :: number, verInfo:Get("minor") :: number, verInfo:Get("patch") :: number,
        verInfo:Get("status") :: string, verInfo:Get("build") :: string, string.sub(verInfo:Get("hash") :: string, 0, 8)

    self:AddEntry("godot_ver")
    self:SetVal("godot_ver", `[b]Godot[/b] {major}.{minor}.{patch}.{status}.{build} [{hash}]`)

    self:addOtherEntry("os_name", "OS")
    self:SetVal("os_name", OS.GetSingleton():GetName())

    local processorName, processorCount =
        OS.GetSingleton():GetProcessorName(),
        OS.GetSingleton():GetProcessorCount()

    self:addOtherEntry("cpu", "CPU")
    self:SetVal("cpu", `{processorName} ({processorCount} logical cores)`)

    local gpuVendor, gpuName, gpuType =
        RenderingServer.GetSingleton():GetVideoAdapterVendor(),
        RenderingServer.GetSingleton():GetVideoAdapterName(),
        RenderingServer.GetSingleton():GetVideoAdapterType()

    self:addOtherEntry("gpu", "GPU")
    self:SetVal("gpu", `{gpuVendor} - {gpuName} - DeviceType: {gpuType}`)

    local gpuDriver, gpuDriverVersion =
        DRIVERS[ProjectSettings.GetSingleton():GetSetting("rendering/renderer/rendering_method")],
        RenderingServer.GetSingleton():GetVideoAdapterApiVersion()

    self:addOtherEntry("gpu_api", "API")
    self:SetVal("gpu_api", `{gpuDriver} {gpuDriverVersion}`)

    self:setOtherVisible(false)
end

function DebugInfoImpl._UnhandledInput(self: DebugInfo, event: InputEvent)
    DebugMenu._UnhandledInput(self, event)

    if event:IsActionPressed("debug_1") then
        self:setOtherVisible(not self.otherVisible)
    end
end

return DebugInfo
