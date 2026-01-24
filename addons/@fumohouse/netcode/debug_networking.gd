extends DebugWindow
## [NetworkManager] debug window.

@onready var _tbl: DebugInfoTable = %DebugInfoTable
@onready var _nm := NetworkManager.get_singleton()


func _init():
	action = &"debug_3"


func _ready():
	super()

	_tbl.add_entry(&"status", "Status")
	_tbl.set_val(
		&"status", "Active - Peer %d" % _nm.local_peer_id if _nm.is_active else "Singleplayer"
	)

	_tbl.add_entry(&"rx", "Packets Received")
	_tbl.add_entry(&"tx", "Packets Sent")
	_tbl.add_entry(&"ping", "Ping")


func _process(delta: float):
	if not _nm.is_active:
		_tbl.set_val(&"tx", "-")
		_tbl.set_val(&"rx", "-")
		_tbl.set_val(&"ping", "-")
		return

	_tbl.set_val(&"rx", str(_nm.packets_received))
	_tbl.set_val(&"tx", str(_nm.packets_sent))
	if _nm.is_server:
		if _nm.get_peers().is_empty():
			_tbl.set_val(&"ping", "Nobody online")
		else:
			var res := ""
			for peer in _nm.get_peers():
				res += "%s - %dms\n" % [_nm.get_peer_identity(peer), _nm.get_peer_rtt(peer)]
			_tbl.set_val(&"ping", res.strip_edges())
	else:
		_tbl.set_val(&"ping", "%dms" % _nm.get_peer_rtt(1))
