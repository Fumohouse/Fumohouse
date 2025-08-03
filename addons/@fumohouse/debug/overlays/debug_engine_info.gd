extends DebugWindow
## Engine information debug window.


const _VSYNC_MODES := {
	DisplayServer.VSYNC_DISABLED: "Disabled",
	DisplayServer.VSYNC_ENABLED: "Enabled",
	DisplayServer.VSYNC_ADAPTIVE: "Adaptive",
	DisplayServer.VSYNC_MAILBOX: "Mailbox",
}

@onready var _tbl: DebugInfoTable = %DebugInfoTable


func _init():
	action = &"debug_2"


func _ready():
	super._ready()

	_tbl.add_entry(&"fps", "FPS")
	_tbl.add_entry(&"process", "Process Time")
	_tbl.add_entry(&"objects", "Object Count")
	_tbl.add_entry(&"render", "Render")
	_tbl.add_entry(&"render_memory", "Render Memory")
	_tbl.add_entry(&"physics", "Physics")
	_tbl.add_entry(&"audio", "Audio")
	_tbl.add_entry(&"navigation", "Navigation")

	if OS.is_debug_build():
		_tbl.add_entry(&"static_memory", "Static Memory Usage")


func _process(_delta: float):
	_tbl.set_val(&"fps", "%d / %d (VSync: %s)" % [
		Performance.get_monitor(Performance.TIME_FPS),
		Engine.max_fps,
		_VSYNC_MODES[DisplayServer.window_get_vsync_mode()],
	])

	_tbl.set_val(&"process", "Process: %.2f ms, Physics: %.2f ms, Nav: %.2f ms" % [
		Performance.get_monitor(Performance.TIME_PROCESS),
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS),
	])

	_tbl.set_val(&"objects", "Obj: %d, Res: %d, Node: %d, Orphan node: %d" % [
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
	])

	_tbl.set_val(&"render", "Objs: %d, Prims: %d, Draw calls: %d" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	])

	_tbl.set_val(&"render_memory", "Tex: %d MB, Buf: %d MB" % [
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1e6,
		Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1e6,
	])

	_tbl.set_val(&"physics", "2D active objs: %d, 2D pairs: %d, 2D islands: %d\n3D active objs: %d, 3D pairs: %d, 3D islands: %d" % [
		Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
		Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS),
		Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT),
		Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
		Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT),
	])

	_tbl.set_val(&"audio", "Latency: %.2f ms" % [
		Performance.get_monitor(Performance.AUDIO_OUTPUT_LATENCY) * 1000,
	])

	_tbl.set_val(&"navigation", "Maps: %d, Regions: %d, Agents: %d, Links: %d, Polys: %d,\nEdges: %d, Edge merges: %d, Edge conns: %d, Edges free: %d" % [
		Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS),
		Performance.get_monitor(Performance.NAVIGATION_REGION_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_AGENT_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_LINK_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_POLYGON_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_EDGE_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_EDGE_MERGE_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_EDGE_CONNECTION_COUNT),
		Performance.get_monitor(Performance.NAVIGATION_EDGE_FREE_COUNT),
	])

	if OS.is_debug_build():
		_tbl.set_val(&"static_memory", "%.2f / %.2f MB" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1e6,
			Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1e6,
		])
