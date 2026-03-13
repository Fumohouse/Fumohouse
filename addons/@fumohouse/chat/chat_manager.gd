class_name ChatManager
extends Node
## Manages TX/RX of chat messages over [NetworkManager].

## Fired whenever a chat message is received. [param sender] can be empty.
signal chat(sender: String, peer: int, content: String)
## Fired whenever a chat message request is initiated.
signal chat_req(id: int, content: String)
## Fired whenever a requested chat message is acknowledged by the server.
signal chat_ack(id: int, status: ChatStatus)

enum ChatStatus {
	## Chat message was accepted and sent to recipients.
	OK = 0
}

const LOG_SCOPE := "Chat"

const ChatBroadcast := preload("./packets/chat_broadcast.gd")
const ChatRequest := preload("./packets/chat_request.gd")

const ChatAck := preload("./packets/chat_ack.gd")

var _next_msg_id := 0

@onready var _nm := NetworkManager.get_singleton()
@onready var _nmr := NetworkManagerRegistry.get_singleton()


static func get_singleton() -> ChatManager:
	return Modules.get_singleton(&"ChatManager") as ChatManager


func _ready():
	_nmr.register_packet(ChatBroadcast.ID, ChatBroadcast.new, ChatRequest.new)
	_nmr.register_packet(ChatAck.ID, ChatAck.new)

	_nmr.register_packet_handler(
		ChatBroadcast.ID, _on_chat_request_server, _on_chat_broadcast_client
	)
	_nmr.register_packet_handler(ChatAck.ID, Callable(), _on_chat_ack_client)


## Request to send a chat message with given [param content]. If not in a
## multiplayer session, [signal chat] is fired directly. Returns the ID
## allocated to this chat message, or [code]-1[/code] if not applicable.
func send_chat(content: String) -> int:
	if not _nm.is_active:
		Log.info("[Local] %s" % [content], LOG_SCOPE)
		chat.emit("Player", 1, content)
		return -1

	if _nm.is_server:
		send_system_message("Server", 0, content)
		return -1

	var req := ChatRequest.new()
	req.msg_id = _next_msg_id
	req.content = content
	_nm.send_packet(1, req)

	chat_req.emit(_next_msg_id, content)
	Log.info("[Local#%d] %s" % [_next_msg_id, content], LOG_SCOPE)

	_next_msg_id += 1
	return req.msg_id


## Broadcast a message with given [param content] to the given [param peer] (or
## broadcast if [code]0[/code]). Server-side only. If not in a multiplayer
## session, [signal chat] is fired directly.
func send_system_message(sender: String, peer: int, content: String):
	if peer == 0:
		chat.emit(sender, 1, content)
	Log.info("[System:%s -> %d] %s" % [sender, peer, content])

	if not _nm.is_active:
		return

	var brd := ChatBroadcast.new()
	brd.sender = sender
	brd.peer = 1
	brd.content = content
	_nm.send_packet(peer, brd)


func _on_chat_request_server(peer: int, packet: ChatRequest):
	# TODO: other logic (e.g., filtering and rate limiting)
	var ack := ChatAck.new()
	ack.msg_id = packet.msg_id
	ack.status = ChatStatus.OK
	_nm.send_packet(peer, ack)

	var sender: String = _nm.get_peer_identity(peer)

	var brd := ChatBroadcast.new()
	brd.sender = sender
	brd.peer = peer
	brd.content = packet.content

	for remote_peer in _nm.get_peers():
		if remote_peer == peer:
			continue
		_nm.send_packet(remote_peer, brd)

	chat.emit(sender, peer, packet.content)
	Log.info("[%s/%d] %s" % [sender, peer, packet.content], LOG_SCOPE)


func _on_chat_broadcast_client(packet: ChatBroadcast):
	chat.emit(packet.sender, packet.peer, packet.content)
	Log.info("[%s/%d] %s" % [packet.sender, packet.peer, packet.content], LOG_SCOPE)


func _on_chat_ack_client(packet: ChatAck):
	chat_ack.emit(packet.msg_id, packet.status)
	Log.info("[ACK#%d] %d" % [packet.msg_id, packet.status], LOG_SCOPE)
