local DebugWindow = require("DebugWindow")
local InfoTable = require("InfoTable")

local DebugEngineInfoImpl = {}
local DebugEngineInfo = gdclass(nil, DebugWindow)
    :Permissions(bit32.bor(Enum.Permissions.INTERNAL, Enum.Permissions.OS))
    :RegisterImpl(DebugEngineInfoImpl)

export type DebugEngineInfo = DebugWindow.DebugWindow & typeof(DebugEngineInfoImpl) & {
    infoTbl: InfoTable.InfoTable,
}

local VSYNC_MODES = {
    [DisplayServer.VSyncMode.DISABLED] = "Disabled",
    [DisplayServer.VSyncMode.ENABLED] = "Enabled",
    [DisplayServer.VSyncMode.ADAPTIVE] = "Adaptive",
    [DisplayServer.VSyncMode.MAILBOX] = "Mailbox",
}

function DebugEngineInfoImpl._Init(self: DebugEngineInfo)
    self.action = "debug_3"
end

function DebugEngineInfoImpl._Ready(self: DebugEngineInfo)
    DebugWindow._Ready(self)
    self:SetWindowVisible(false)

    local infoTbl = self:GetNode("%InfoTable") :: InfoTable.InfoTable
    self.infoTbl = infoTbl

    infoTbl:AddEntry("fps", "FPS")
    infoTbl:AddEntry("process", "Process Time")
    infoTbl:AddEntry("objects", "Object Count")
    infoTbl:AddEntry("render", "Render")
    infoTbl:AddEntry("renderMemory", "Render Memory")
    infoTbl:AddEntry("physics", "Physics")
    infoTbl:AddEntry("audio", "Audio")
    infoTbl:AddEntry("navigation", "Navigation")

    if OS.singleton:IsDebugBuild() then
        infoTbl:AddEntry("staticMemory", "Static Memory Usage")
    end
end

DebugEngineInfo:RegisterMethod("_Ready")

function DebugEngineInfoImpl._Process(self: DebugEngineInfo, delta: number)
    local infoTbl = self.infoTbl
    local perf = Performance.singleton

    local vsyncMode = ProjectSettings.singleton:GetSetting("display/window/vsync/vsync_mode") :: ClassEnumDisplayServer_VSyncMode
    infoTbl:SetVal("fps", string.format(
        "%d / %d (VSync: %s)",
        perf:GetMonitor(Performance.Monitor.TIME_FPS),
        Engine.singleton.maxFps,
        VSYNC_MODES[vsyncMode]
    ))

    infoTbl:SetVal("process", string.format(
        "Process: %.2f ms, Physics: %.2f ms, Nav: %.2f ms",
        perf:GetMonitor(Performance.Monitor.TIME_PROCESS) * 1000,
        perf:GetMonitor(Performance.Monitor.TIME_PHYSICS_PROCESS) * 1000,
        perf:GetMonitor(Performance.Monitor.TIME_NAVIGATION_PROCESS) * 1000
    ))

    infoTbl:SetVal("objects", string.format(
        "Obj: %d, Res: %d, Node: %d, Orphan: %d",
        perf:GetMonitor(Performance.Monitor.OBJECT_COUNT),
        perf:GetMonitor(Performance.Monitor.OBJECT_RESOURCE_COUNT),
        perf:GetMonitor(Performance.Monitor.OBJECT_NODE_COUNT),
        perf:GetMonitor(Performance.Monitor.OBJECT_ORPHAN_NODE_COUNT)
    ))

    infoTbl:SetVal("render", string.format(
        "Objs: %d, Prims: %d, Draw calls: %d",
        perf:GetMonitor(Performance.Monitor.RENDER_TOTAL_OBJECTS_IN_FRAME),
        perf:GetMonitor(Performance.Monitor.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
        perf:GetMonitor(Performance.Monitor.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    ))

    infoTbl:SetVal("renderMemory", string.format(
        "Tex: %d MB, Buf: %d MB",
        perf:GetMonitor(Performance.Monitor.RENDER_TEXTURE_MEM_USED) / 1e6,
        perf:GetMonitor(Performance.Monitor.RENDER_BUFFER_MEM_USED) / 1e6
    ))

    infoTbl:SetVal("physics", string.format(
        "2D Active Objs: %d, 2D Pairs: %d, 2D Islands: %d\n3D Active Objs: %d, 3D Pairs: %d, 3D Islands: %d",
        perf:GetMonitor(Performance.Monitor.PHYSICS_2D_ACTIVE_OBJECTS),
        perf:GetMonitor(Performance.Monitor.PHYSICS_2D_COLLISION_PAIRS),
        perf:GetMonitor(Performance.Monitor.PHYSICS_2D_ISLAND_COUNT),
        perf:GetMonitor(Performance.Monitor.PHYSICS_3D_ACTIVE_OBJECTS),
        perf:GetMonitor(Performance.Monitor.PHYSICS_3D_COLLISION_PAIRS),
        perf:GetMonitor(Performance.Monitor.PHYSICS_3D_ISLAND_COUNT)
    ))

    infoTbl:SetVal("audio", string.format(
        "Latency: %.2f ms",
        perf:GetMonitor(Performance.Monitor.AUDIO_OUTPUT_LATENCY) * 1000
    ))

    infoTbl:SetVal("navigation", string.format(
        "Maps: %d, Regions: %d, Agents: %d, Links: %d, Polys: %d,\nEdges: %d, Edge merges: %d, Edge conns: %d, Edges free: %d",
        perf:GetMonitor(Performance.Monitor.NAVIGATION_ACTIVE_MAPS),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_REGION_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_AGENT_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_LINK_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_POLYGON_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_EDGE_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_EDGE_MERGE_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_EDGE_CONNECTION_COUNT),
        perf:GetMonitor(Performance.Monitor.NAVIGATION_EDGE_FREE_COUNT)
    ))

    if OS.singleton:IsDebugBuild() then
        infoTbl:SetVal("staticMemory", string.format(
            "%.2f / %.2f MB",
            perf:GetMonitor(Performance.Monitor.MEMORY_STATIC) / 1e6,
            perf:GetMonitor(Performance.Monitor.MEMORY_STATIC_MAX) / 1e6
        ))
    end
end

DebugEngineInfo:RegisterMethodAST("_Process")

return DebugEngineInfo
