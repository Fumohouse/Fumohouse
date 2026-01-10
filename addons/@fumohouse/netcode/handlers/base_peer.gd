extends Node
## Handles handshake and peer status. This class is an extension of
## [NetworkManager] and accesses its private variables.

const HelloServer := preload("../packets/hello_server.gd")
const HelloClient := preload("../packets/hello_client.gd")

const Sync := preload("../packets/sync.gd")
const Auth := preload("../packets/auth.gd")

const Goodbye := preload("../packets/goodbye.gd")

const PeerState := preload("../packets/peer_state.gd")

@onready var _nm := NetworkManager.get_singleton()
@onready var _nmr := NetworkManagerRegistry.get_singleton()


func _ready():
	_nm.server_peer_connected.connect(_on_server_peer_connected)
	_nm.server_peer_disconnected.connect(_on_server_peer_disconnected)

	_nm.client_connected.connect(_on_client_connected)

	_nmr.register_packet(HelloServer.ID, HelloServer.new, HelloClient.new)
	_nmr.register_packet(Sync.ID, Sync.new, Auth.new)
	_nmr.register_packet(Goodbye.ID, Goodbye.new, Goodbye.new)
	_nmr.register_packet(PeerState.ID, PeerState.new)

	_nmr.register_packet_handler(HelloServer.ID, _on_hello_server, _on_hello_client)
	_nmr.register_packet_handler(Sync.ID, _on_auth_server, _on_sync_client)
	_nmr.register_packet_handler(Goodbye.ID, _on_goodbye_server, _on_goodbye_client)
	_nmr.register_packet_handler(PeerState.ID, Callable(), _on_peer_state_client)


func _on_server_peer_connected(peer: int):
	# Disconnect if handshake does not proceed (expecting HELLOC)
	_nm.disconnect_timeout(
		peer, func(): return _nm.get_peer_state(peer) == NetworkManager.PeerState.CONNECTED
	)


func _on_server_peer_disconnected(peer: int):
	var psp := PeerState.new()
	psp.peer = peer
	psp.identity = _nm.get_peer_identity(peer)
	psp.status = NetworkManager.PeerStateUpdate.LEFT
	_send_psp(psp)


func _on_client_connected():
	# HANDSHAKE: 1) Client HELLO
	var hello := HelloClient.new()
	hello.version = DistConfig.VERSION_NUM
	hello.identity = _nm._identity
	_nm.send_packet(1, hello)

	# Disconnect if handshake does not proceed (expecting HELLOS)
	_nm.disconnect_timeout(
		1, func(): return _nm.get_peer_state(1) == NetworkManager.PeerState.CONNECTED
	)


func _on_hello_server(peer: int, packet: HelloClient):
	var peer_data: NetworkManager.PeerData = _nm._peers.get(peer)
	if not peer_data:
		return

	if peer_data.state != NetworkManager.PeerState.CONNECTED:
		_nm.disconnect_with_reason(peer, "Incorrect stage for handshake begin")
		return

	if packet.version != DistConfig.VERSION_NUM:
		_nm.disconnect_with_reason(
			peer,
			(
				"Fumohouse version mismatch — server: %d; you: %d"
				% [DistConfig.VERSION_NUM, packet.version]
			)
		)
		return

	peer_data.identity = packet.identity

	var auth_type: NetworkManager.AuthType = NetworkManager.AuthType.NONE
	if not _nm._auth.is_empty():
		auth_type = NetworkManager.AuthType.PASSWORD

	# HANDSHAKE: 2) Server HELLO
	var hello := HelloServer.new()
	hello.auth_type = auth_type
	_nm.send_packet(peer, hello)

	peer_data.state = NetworkManager.PeerState.AUTH
	# Disconnect if handshake does not proceed (expecting AUTH)
	_nm.disconnect_timeout(
		peer, func(): return _nm.get_peer_state(peer) == NetworkManager.PeerState.AUTH
	)


func _on_hello_client(packet: HelloServer):
	var peer_data: NetworkManager.PeerData = _nm._peers.get(1)
	if not peer_data:
		return

	if peer_data.state != NetworkManager.PeerState.CONNECTED:
		_nm.disconnect_with_reason(1, "Incorrect stage for handshake begin")
		return

	# HANDSHAKE: 3) Client AUTH
	var auth := Auth.new()
	if packet.auth_type == NetworkManager.AuthType.PASSWORD:
		auth.auth_data = _nm._auth
	_nm.send_packet(1, auth)

	peer_data.state = NetworkManager.PeerState.AUTH
	# Disconnect if handshake does not proceed (expecting SYNC)
	_nm.disconnect_timeout(1, func(): return _nm.get_peer_state(1) == NetworkManager.PeerState.AUTH)

	_nm.send_status_update("Authenticating...", false, false)


func _on_auth_server(peer: int, packet: Auth):
	var peer_data: NetworkManager.PeerData = _nm._peers.get(peer)
	if not peer_data:
		return

	if peer_data.state != NetworkManager.PeerState.AUTH:
		_nm.disconnect_with_reason(peer, "Incorrect stage for authentication")
		return

	if not _nm._auth.is_empty():
		if packet.auth_data != _nm._auth:
			_nm.disconnect_with_reason(peer, "Incorrect password")
			return

	peer_data.state = NetworkManager.PeerState.JOINED
	print("[Networking] Peer %d joined as %s" % [peer, peer_data.identity])

	# HANDSHAKE: 4) Server SYNC
	var sync := Sync.new()
	var remote_peers: Dictionary[int, NetworkManager.PeerData] = {}
	for remote_peer in _nm._peers:
		if peer == remote_peer:
			continue

		var remote_peer_data: NetworkManager.PeerData = _nm._peers[remote_peer]
		if remote_peer_data.state < NetworkManager.PeerState.JOINED:
			continue

		remote_peers[remote_peer] = remote_peer_data
	sync.peers = remote_peers
	_nm.send_packet(peer, sync)

	var psp := PeerState.new()
	psp.peer = peer
	psp.identity = peer_data.identity
	psp.status = NetworkManager.PeerStateUpdate.JOINED
	_send_psp(psp)

	_nm.server_peer_joined.emit(peer)


func _on_sync_client(packet: Sync):
	# HANDSHAKE: END
	var peer_data: NetworkManager.PeerData = _nm._peers.get(1)
	if not peer_data:
		return

	if peer_data.state != NetworkManager.PeerState.AUTH:
		_nm.disconnect_with_reason(1, "Incorrect stage for sync")
		return

	peer_data.state = NetworkManager.PeerState.JOINED
	print("[Networking] Successfully joined as %s" % _nm._identity)

	for remote_peer in packet.peers:
		var remote_peer_data: NetworkManager.PeerData = packet.peers[remote_peer]
		remote_peer_data.state = NetworkManager.PeerState.JOINED
		_nm._peers[remote_peer] = remote_peer_data

	_nm.client_joined.emit()


func _on_goodbye_server(peer: int, packet: Goodbye):
	print("[Networking] Peer %d disconnected: %s" % [peer, packet.reason])
	_nm.disconnect_no_reason(peer)


func _on_goodbye_client(packet: Goodbye):
	print("[Networking] Disconnected by server: %s" % packet.reason)
	_nm.reset()
	_nm.send_status_update("Disconnected: " + packet.reason, true, false)


func _on_peer_state_client(packet: PeerState):
	if packet.status == NetworkManager.PeerStateUpdate.JOINED:
		print("[Networking] Peer %d (%s) joined the game" % [packet.peer, packet.identity])
		var remote_peer_data := NetworkManager.PeerData.new()
		remote_peer_data.state = NetworkManager.PeerState.JOINED
		remote_peer_data.identity = packet.identity
		_nm._peers[packet.peer] = remote_peer_data
	elif packet.status == NetworkManager.PeerStateUpdate.LEFT:
		print("[Networking] Peer %d (%s) left the game" % [packet.peer, packet.identity])
		_nm._peers.erase(packet.peer)


func _send_psp(psp: PeerState):
	for remote_peer in _nm.get_peers():
		if (
			remote_peer == psp.peer
			or _nm.get_peer_state(remote_peer) < NetworkManager.PeerState.JOINED
		):
			continue
		_nm.send_packet(remote_peer, psp)
