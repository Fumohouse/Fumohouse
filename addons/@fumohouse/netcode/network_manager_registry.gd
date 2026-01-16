class_name NetworkManagerRegistry
extends Node
## Manages packets and packet handlers for [NetworkManager].

## Registry of packet constructors and handlers. Nested array where each index
## is a packet ID byte (each layer is 256 in size). Terminal is a
## [PacketRegistryEntry], or null.
var _packet_registry: Array[Variant] = []


static func get_singleton() -> NetworkManagerRegistry:
	return Modules.get_singleton(&"NetworkManagerRegistry") as NetworkManagerRegistry


## Register a packet type.
func register_packet(id: PackedByteArray, ctor_server := Callable(), ctor_client := Callable()):
	var entry := PacketRegistryEntry.new()
	entry.ctor_server = ctor_server
	entry.ctor_client = ctor_client

	var curr: Array[Variant] = _packet_registry
	for byte in id:
		if byte <= 0x7F:
			if curr.is_empty():
				curr.resize(256)
				for i in 256:
					if i <= 0x7F:
						curr[i] = null
					else:
						curr[i] = []

			curr[byte] = entry
			return

		if curr.is_empty():
			curr.resize(256)
			for i in 256:
				if i <= 0x7F:
					curr[i] = null
				else:
					curr[i] = []

		curr = curr[byte]

	push_error("Invalid packet ID %s." % id)


## Register a packet handler. Server-side handlers take two arguments, peer ID
## and the packet. Client-side handlers take one argument, the packet.
func register_packet_handler(
	id: PackedByteArray, handler_server := Callable(), handler_client := Callable()
):
	var pre: PacketRegistryEntry = _get_packet_registry_entry(id)
	if not pre:
		return

	if handler_server.is_valid():
		pre.handlers_server.push_back(handler_server)
	if handler_client.is_valid():
		pre.handlers_client.push_back(handler_client)


## Handle incoming packets in the given [param data] buffer. If [param peer] is
## [code]1[/code], use clientside handling. Otherwise, use serverside handling.
## Multiple contiguous packets are supported.
func handle_packets(peer: int, data: PackedByteArray):
	var de := Deserializer.new(data)
	while not de.eof():
		var length: int = de.varuint()
		var next_pos: int = de.pos + length
		var pre: PacketRegistryEntry = _get_packet_registry_entry(data, de.pos)
		if not pre:
			de.seek(next_pos)
			continue

		var packet: NetworkPacket
		if peer == 1:
			# On the client -> server-origin
			if not pre.ctor_server.is_valid():
				de.seek(next_pos)
				continue

			packet = pre.ctor_server.call()
		else:
			# On the server -> client-origin
			if not pre.ctor_client.is_valid():
				de.seek(next_pos)
				continue

			packet = pre.ctor_client.call()

		de.seek(de.pos + packet.id.size())
		packet._serde(de)

		if de.pos != next_pos:
			push_error("Failed to parse packet: Declared length does not match parsed length")
			return

		if peer == 1:
			# On the client -> client handlers
			for handler in pre.handlers_client:
				if not handler.is_valid():
					continue
				handler.call(packet)
		else:
			# On the server -> server handlers
			for handler in pre.handlers_server:
				if not handler.is_valid():
					continue
				handler.call(peer, packet)


func _get_packet_registry_entry(id: PackedByteArray, ofs := 0) -> PacketRegistryEntry:
	var curr: Array[Variant] = _packet_registry
	for i in range(ofs, id.size()):
		if curr.is_empty():
			return null

		var byte: int = id[i]
		if byte <= 0x7F:
			return curr[byte]
		else:
			curr = curr[byte]

	push_error("Invalid packet ID %s." % id)
	return null


class PacketRegistryEntry:
	extends RefCounted
	## Function with no arguments that returns a new instance of the
	## server-origin version of this packet. Empty for none.
	var ctor_server := Callable()
	## Function with no arguments that returns a new instance of the
	## client-origin version of this packet. Empty for none.
	var ctor_client := Callable()
	## List of server-side handlers for this packet. Each function takes two
	## arguments, the peer ID and the packet.
	var handlers_server: Array[Callable] = []
	## List of client-side handlers for this packet. Each function takes one
	## argument, the packet.
	var handlers_client: Array[Callable] = []
