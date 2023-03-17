local DebugWindow = require("DebugWindow")
local InfoTable = require("InfoTable")
local Utils = require("../../utils/Utils.mod")

local DebugPlatformInfoImpl = {}
local DebugPlatformInfo = gdclass(nil, DebugWindow)
    :Permissions(bit32.bor(Enum.Permissions.INTERNAL, Enum.Permissions.OS))
    :RegisterImpl(DebugPlatformInfoImpl)

type DebugPlatformInfoT = DebugWindow.DebugWindowT & {
    infoTbl: InfoTable.InfoTable,
    egg: number,
}

export type DebugPlatformInfo = DebugWindow.DebugWindow & DebugPlatformInfoT & typeof(DebugPlatformInfoImpl)

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

function DebugPlatformInfoImpl._Init(obj: Control, tbl: DebugPlatformInfoT)
    tbl.action = "debug_1"
    tbl.egg = 1
end

function DebugPlatformInfoImpl.updateEgg(self: DebugPlatformInfo)
    local effect = EFFECTS[self.egg]
    self.infoTbl:SetVal("build", `[b]Fumohouse[/b] {effect[1]}[url=egg]{Utils.GetBuildString()}[/url]{effect[2]}`)
end

function DebugPlatformInfoImpl._OnMetaClicked(self: DebugPlatformInfo, meta: Variant)
    if meta == "egg" then
        self.egg += 1
        if self.egg == #EFFECTS + 1 then
            self.egg = 1
        end

        self:updateEgg()
    elseif meta == "panku" then
        OS.GetSingleton():ShellOpen("https://github.com/Ark2000/PankuConsole")
    end
end

DebugPlatformInfo:RegisterMethodAST("_OnMetaClicked")

function DebugPlatformInfoImpl._Ready(self: DebugPlatformInfo)
    DebugWindow._Ready(self)
    self:SetWindowVisible(false)

    local infoTbl = self:GetNode("%InfoTable") :: InfoTable.InfoTable
    self.infoTbl = infoTbl

    local metaCb = Callable.new(self, "_OnMetaClicked")

    local contents = infoTbl:AddEntry("build").contents
    contents.metaClicked:Connect(metaCb)
    contents.metaUnderlined = false

    local verInfo = Engine.GetSingleton():GetVersionInfo()
    local major, minor, patch, status, build, hash =
        verInfo:Get("major") :: number, verInfo:Get("minor") :: number, verInfo:Get("patch") :: number,
        verInfo:Get("status") :: string, verInfo:Get("build") :: string, string.sub(verInfo:Get("hash") :: string, 0, 8)

    infoTbl:AddEntry("godotVer")
    infoTbl:SetVal("godotVer", `[b]Godot[/b] {major}.{minor}.{patch}.{status}.{build} [{hash}]`)

    infoTbl:AddEntry("osName", "OS")
    infoTbl:SetVal("osName", `{OS.GetSingleton():GetName()} ({Engine.GetSingleton():GetArchitectureName()})`)

    local processorName, processorCount =
        OS.GetSingleton():GetProcessorName(),
        OS.GetSingleton():GetProcessorCount()

    infoTbl:AddEntry("cpu", "CPU")
    infoTbl:SetVal("cpu", `{processorName} ({processorCount} logical cores)`)

    local gpuVendor, gpuName, gpuType =
        RenderingServer.GetSingleton():GetVideoAdapterVendor(),
        RenderingServer.GetSingleton():GetVideoAdapterName(),
        RenderingServer.GetSingleton():GetVideoAdapterType()

    infoTbl:AddEntry("gpu", "GPU")
    infoTbl:SetVal("gpu", `{gpuVendor} - {gpuName} - DeviceType: {gpuType}`)

    local gpuDriver, gpuDriverVersion =
        DRIVERS[ProjectSettings.GetSingleton():GetSetting("rendering/renderer/rendering_method")],
        RenderingServer.GetSingleton():GetVideoAdapterApiVersion()

    infoTbl:AddEntry("gpuApi", "API")
    infoTbl:SetVal("gpuApi", `{gpuDriver} {gpuDriverVersion}`)

    local inspired = infoTbl:AddEntry("inspired").contents
    inspired.metaClicked:Connect(metaCb)
    inspired.text = "Debug menus inspired by [url=panku]Panku Console[/url]"

    self:updateEgg()
end

DebugPlatformInfo:RegisterMethod("_Ready")

return DebugPlatformInfo
