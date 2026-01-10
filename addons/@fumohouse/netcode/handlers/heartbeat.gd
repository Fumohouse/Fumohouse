extends Node
## Handles heartbeat (periodic ping). This class is an extension of
## [NetworkManager] and accesses its private variables.

const Ping := preload("../packets/ping.gd")
const PING_INTERVAL := 1.0

var _next_ping := 0.0

@onready var _nm := NetworkManager.get_singleton()
@onready var _nmr := NetworkManagerRegistry.get_singleton()


func _ready():
	_nmr.register_packet(Ping.ID, Ping.new, Ping.new)
	_nmr.register_packet_handler(
		Ping.ID, _on_ping_common, func(packet: NetworkPacket): _on_ping_common(1, packet)
	)


func _process(delta: float):
	if not _nm.is_active:
		return

	if _next_ping == 0.0:
		if _nm.is_server:
			for peer in _nm.get_peers():
				if _nm.get_peer_state(peer) < NetworkManager.PeerState.JOINED:
					continue

				_ping(peer)
		elif _nm.get_peer_state(1) >= NetworkManager.PeerState.JOINED:
			_ping(1)

		_next_ping = PING_INTERVAL
	else:
		_next_ping = move_toward(_next_ping, 0.0, delta)


func _on_ping_common(peer: int, packet: Ping):
	if peer not in _nm._peers:
		return

	if packet.pong:
		var rtt: float = (Time.get_ticks_usec() - packet.payload) / 1000.0
		_nm._peers[peer].rtt = rtt
		_nm._peers[peer].successful_pings += 1
	else:
		var pong := Ping.new()
		pong.pong = true
		pong.payload = packet.payload
		_nm.send_packet(peer, pong)


func _ping(peer: int):
	var ping := Ping.new()
	ping.pong = false
	ping.payload = Time.get_ticks_usec()
	_nm.send_packet(peer, ping)

	var existing_pings: int = _nm._peers[peer].successful_pings
	_nm.disconnect_timeout(
		peer,
		func(): return peer in _nm._peers and _nm._peers[peer].successful_pings == existing_pings
	)
