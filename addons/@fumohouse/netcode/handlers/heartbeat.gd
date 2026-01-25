extends Node
## Handles heartbeat (periodic ping) and clock synchronization. This class is an
## extension of [NetworkManager] and accesses its private variables.

const Ping := preload("../packets/ping.gd")
const PING_INTERVAL := 1.0

var _next_ping := 0.0
var _clock_samples: Array[ClockTimeSample] = []

@onready var _nm := NetworkManager.get_singleton()
@onready var _nmr := NetworkManagerRegistry.get_singleton()


func _ready():
	_nm.resetted.connect(_on_nm_reset)

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


func _on_nm_reset():
	_clock_samples.clear()


func _on_ping_common(peer: int, packet: Ping):
	if peer not in _nm._peers:
		return

	if packet.pong:
		var rtt_ticks: int = Time.get_ticks_usec() - packet.payload
		var rtt: float = rtt_ticks / 1000.0
		_nm._peers[peer].rtt = rtt
		_nm._peers[peer].successful_pings += 1

		if not _nm.is_server:
			_update_clock(packet.time, rtt_ticks)
	else:
		var pong := Ping.new()
		pong.pong = true
		pong.payload = packet.payload
		pong.time = _nm.time
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


func _update_clock(time: int, rtt: int):
	# https://web.archive.org/web/20181107022429/http://www.mine-control.com/zack/timesync/timesync.html
	var sample := ClockTimeSample.new()
	sample.offset = time - Time.get_ticks_usec() + rtt / 2
	sample.rtt = rtt
	_clock_samples.push_back(sample)
	_clock_samples.sort_custom(func(a: ClockTimeSample, b: ClockTimeSample): return a.rtt < b.rtt)

	var sz: int = _clock_samples.size()

	# Mean, median, stdev
	var median: int = _clock_samples[sz / 2].rtt
	var mean := 0
	for s in _clock_samples:
		mean += s.rtt
	mean /= sz

	var stdev := 0
	if sz > 1:
		for s in _clock_samples:
			var ofs: int = s.rtt - mean
			stdev += ofs * ofs
		stdev = sqrt(stdev / (sz - 1))

	# Remove outlier RTT samples
	_clock_samples = _clock_samples.filter(
		func(s: ClockTimeSample): return s.rtt >= median - 2 * stdev and s.rtt <= median + 2 * stdev
	)

	# Remove more than 5 samples
	sz = _clock_samples.size()
	if _clock_samples.size() > 5:
		_clock_samples = _clock_samples.slice(sz / 2 - 2, sz / 2 + 3)
		sz = _clock_samples.size()

	# Find final offset
	mean = 0
	for s in _clock_samples:
		mean += s.offset
	mean /= sz

	_nm._clock_offset = mean


class ClockTimeSample:
	extends RefCounted
	var offset := 0
	var rtt := 0.0
