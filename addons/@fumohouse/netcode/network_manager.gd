class_name NetworkManager
extends Node
## Manages multiplayer networking with low(er) level packets.

## Fired after the server starts.
signal server_started

## Fired after the client connection succeeds (prior to handshake).
signal client_connected
## Fired after the client completes the handshake.
signal client_joined
## Fired after a remote peer completes the handshake.
signal client_peer_joined(id: int)
## Fired after a remote peer disconnects from the server.
signal client_peer_disconnected(id: int)

## Fired after a peer connects to the server (prior to handshake).
signal server_peer_connected(id: int)
## Fired after a peer completes the handshake.
signal server_peer_joined(id: int)
## Fired after a peer disconnects from the server.
signal server_peer_disconnected(id: int)

## Generic status update (for use with UI, etc.)
signal status_update(msg: String, failure: bool)

## Fired after the networking system resets. May be used for clearing previously
## stored state.
signal resetted

enum PeerState {
	## Peer is not connected.
	DISCONNECTED = 0,
	## Peer has connected but handshake has not started.
	CONNECTED = 1,
	## Server-side: Awaiting client AUTH packet. Client-side: Awaiting server
	## response to AUTH.
	AUTH = 2,
	# All following states are post-handshake
	## Peer has completed handshake.
	JOINED = 10,
}

enum PeerStateUpdate {
	## Peer has joined.
	JOINED = 0,
	## Peer has left.
	LEFT = 1,
}

enum AuthType {
	## No authentication required.
	NONE = 0,
	## Password required to join.
	PASSWORD = 1,
}

const Goodbye := preload("packets/goodbye.gd")

## Currently in multiplayer? (i.e., not singleplayer)
var is_active: bool:
	get:
		return _is_active

## Acting as the server? Returns [code]true[/code] if offline.
var is_server: bool:
	get:
		return _mp.is_server()

## Current peer ID.
var local_peer_id: int:
	get:
		return _peer.get_unique_id() if _peer else 0

## Local player identity.
var local_identity: String:
	get:
		return _identity

## Getter for custom payload for [code]HELLOS[/code]. If non-empty, this
## function is called when the server sends [code]HELLOS[/code] and its output
## is injected into the packet payload. Function should take no arguments and
## return a buffer.
var get_negotiation_payload := Callable()
## Handler for custom negotiation payload. If non-empty, this function is called
## when the client receives the [code]HELLOS[/code] packet. Function should take
## in a buffer and return [code]true[/code] if the handshake should continue,
## and [code]false[/code] otherwise. The function may be asynchronous. When
## canceling the handshake, use [method disconnect_with_reason].
var handle_negotiation_payload := Callable()

## Increments on [method reset]. Used to detect in delayed functions whether
## the networking session was terminated.
var _generation := 0

var _is_active := false
var _is_quitting := false
## If on server, this is the password required to join. If on client, this is
## used to authenticate with the server depending on what authentication method
## is requested.
var _auth := ""

# Client state
var _addr := ""
var _port := 0
var _identity := ""

# FIXME: Pending https://github.com/godotengine/godot-proposals/issues/10627
# It would be better to use ENet + DTLS, currently impossible
var _peer: WebSocketMultiplayerPeer
var _peers: Dictionary[int, PeerData] = {}
var _body_ser := Serializer.new([])
var _ser := Serializer.new([])

@onready var _nmr := NetworkManagerRegistry.get_singleton()
@onready var _mp: SceneMultiplayer = multiplayer as SceneMultiplayer


static func get_singleton() -> NetworkManager:
	return Modules.get_singleton(&"NetworkManager") as NetworkManager


func _ready():
	reset()

	# Do not allow client-to-client transfers
	_mp.server_relay = false

	# Client-side signals
	_mp.connected_to_server.connect(_on_connected_to_server)
	_mp.connection_failed.connect(_on_connection_failed)
	_mp.server_disconnected.connect(_on_server_disconnected)

	# Server-side signals
	_mp.peer_connected.connect(_on_peer_connected)
	_mp.peer_disconnected.connect(_on_peer_disconnected)

	# Common
	_mp.peer_packet.connect(_on_peer_packet)

	QuitManager.get_singleton().register_quit_inhibitor(_on_quitting)


## Start a multiplayer session as the server. If provided, require players to
## enter [param password] to join.
func serve(port: int, password := "") -> Error:
	if _peer and _peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		send_status_update("Server is already running", true, false)
		return ERR_ALREADY_EXISTS

	await send_status_update("Starting server…")

	var crypto := Crypto.new()
	var key: CryptoKey = crypto.generate_rsa(4096)
	var cert: X509Certificate = crypto.generate_self_signed_certificate(
		key,
		"CN=Fumohouse,O=Fumohouse,C=US",
		"20140101000000",
		"%s0101000000" % (Time.get_date_dict_from_system()["year"] + 1)
	)
	var tls := TLSOptions.server(key, cert)

	_auth = password

	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_server(port, "*", tls)
	if err != OK:
		send_status_update("Failed to start server", true, false)
		return err

	_mp.multiplayer_peer = _peer

	_is_active = true
	server_started.emit()
	print("[Networking] Started server at port %d" % port)
	return OK


## Start a multiplayer session as a client.
func join(addr: String, port: int, identity: String, auth := "") -> Error:
	if _peer and _peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		return ERR_ALREADY_EXISTS

	await send_status_update("Connecting…")

	_auth = auth
	_addr = addr
	_port = port
	_identity = identity

	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_client("wss://%s:%d" % [addr, port], TLSOptions.client_unsafe())
	if err != OK:
		send_status_update("Failed to create client", true, false)
		return err

	_mp.multiplayer_peer = _peer

	_is_active = true
	print("[Networking] Connecting to server at %s:%d..." % [addr, port])
	return OK


## Disconnect the given [param peer] without reason.
func disconnect_no_reason(peer: int):
	if peer not in _peers:
		return

	_mp.disconnect_peer(peer)

	# FIXME: Should NOT be necessary
	# https://github.com/godotengine/godot-docs-user-notes/discussions/134#discussioncomment-14977574
	if peer in _peers:
		# Signal did not fire
		_on_peer_disconnected(peer)


## Disconnect the given [param peer] after the given [param timeout] (seconds),
## as long as [param predicate] is empty or returns a truthy value.
func disconnect_timeout(peer: int, predicate := Callable(), timeout := 10.0):
	var generation: int = _generation
	await get_tree().create_timer(timeout).timeout

	if (predicate.is_valid() and not predicate.call()) or _generation != generation:
		return

	if is_server:
		var peer_data: PeerData = _peers.get(peer)
		if not peer_data:
			# Already disconnected
			return

		print("[Networking] Disconnecting peer %d after timeout" % peer)
		disconnect_no_reason(peer)
	else:
		print("[Networking] Disconnecting from server after timeout")
		reset()
		send_status_update("Timed out", true, false)


## Disconnect the given [param peer] with [param reason]. If [param do_timeout]
## is [code]true[/code], disconnects the peer after timeout if it hasn't done
## so already.
func disconnect_with_reason(peer: int, reason: String, do_timeout := true):
	var bye := Goodbye.new()
	bye.reason = reason
	send_packet(peer, bye)

	if do_timeout:
		disconnect_timeout(peer)

	if not is_server:
		send_status_update("Disconnected: " + reason, true, false)


## Stop the currently running server. Disconnects all clients and waits for
## acknowldgement or until a timeout before exiting.
func close_server():
	if not _peer or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	print("[Networking] Closing server...")

	_mp.refuse_new_connections = true
	disconnect_with_reason(0, "Server closed")

	# Wait for clients to acknowledge packet by leaving, or quit after a bit
	const MAX_WAIT := 5.0
	const ATTEMPTS := 50

	for i in ATTEMPTS:
		if _mp.get_peers().is_empty():
			print("[Networking] All clients disconnected!")
			break

		await get_tree().create_timer(MAX_WAIT / ATTEMPTS).timeout

	reset()


## Reset the networking system, returning the game to singleplayer.
func reset():
	if _peer:
		_peer.close()
	_peer = null

	_is_active = false
	_mp.multiplayer_peer = OfflineMultiplayerPeer.new()

	_peers.clear()

	_auth = ""
	_addr = ""
	_port = 0
	_identity = ""

	_generation += 1
	resetted.emit()

	if _is_quitting:
		print("[NetworkManager] Continuing quit process...")
		QuitManager.get_singleton().quit()


## Send the given [param packet] to the given [param peer], immediately.
func send_packet(peer: int, packet: NetworkPacket):
	if (
		_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED
		or (peer > 0 and not _mp.get_peers().has(peer))
	):
		return

	_body_ser.seek(0)
	_ser.seek(0)

	packet._serde(_body_ser)

	_ser.varuint(packet.id.size() + _body_ser.pos)
	_ser.buffer(packet.id)
	_ser.ser(_body_ser)

	_mp.send_bytes(_ser.to_buffer(), peer, packet.mode, packet.channel)


## Send a status update message (e.g., to display in UI).
func send_status_update(msg: String, failure := false, ui_wait := true):
	status_update.emit(msg, failure)
	if ui_wait:
		await CommonUtils.wait_for_ui_update(self)


## Get a list of currently connected peer IDs.
func get_peers() -> PackedInt64Array:
	return _peers.keys()


## Get the current state of the given [param peer].
func get_peer_state(peer: int) -> PeerState:
	var data: PeerData = _peers.get(peer)
	if not data:
		return PeerState.DISCONNECTED
	return data.state


## Get peer identity (i.e., username), or empty if the peer does not exist.
func get_peer_identity(peer: int) -> String:
	var data: PeerData = _peers.get(peer)
	if not data:
		return ""
	return data.identity


func _on_connected_to_server():
	print("[Networking] Successfully connected to %s:%d" % [_addr, _port])

	var peer_data := PeerData.new()
	peer_data.identity = "SERVER"
	_peers[1] = peer_data

	# Handshake continues in base_peer.gd
	client_connected.emit()


func _on_connection_failed():
	print("[Networking] Connection to %s:%d failed" % [_addr, _port])
	reset()
	send_status_update("Connection failed", true, false)


func _on_server_disconnected():
	print("[Networking] Disconnected from server")
	reset()


func _on_peer_connected(id: int):
	if not is_server:
		return

	print(
		(
			"[Networking] New peer %d @ %s:%d"
			% [id, _peer.get_peer_address(id), _peer.get_peer_port(id)]
		)
	)

	_peers[id] = PeerData.new()

	# Handshake continues in base_peer.gd
	server_peer_connected.emit(id)


func _on_peer_disconnected(id: int):
	if not is_server:
		return

	print("[Networking] Peer %d disconnected" % id)

	server_peer_disconnected.emit(id)
	# After to preserve peer data during disconnected event
	_peers.erase(id)


func _on_peer_packet(id: int, data: PackedByteArray):
	_nmr.handle_packets(id, data)


func _on_quitting():
	if not _peer or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return false

	print("[Networking] Preparing to quit...")

	_is_quitting = true

	if is_server:
		close_server()
	else:
		disconnect_with_reason(1, "Disconnected")

	# Need to wait for quits to be acknowledged. Once NetworkManager is reset,
	# the quit process will continue.
	return true


class PeerData:
	extends RefCounted
	## Peer state.
	var state := PeerState.CONNECTED
	## Client identity (i.e., username).
	var identity := ""

	## Number of successful pings.
	var successful_pings := 0
	## Last round-trip ping time, in milliseconds.
	var rtt := 0.0
