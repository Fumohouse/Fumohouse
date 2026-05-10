extends "../character_billboard.gd"

const ChatBubble := preload("chat_bubble.gd")
const _CHAT_BUBBLE := preload("chat_bubble.tscn")

@export var fumo: Fumo
@export var voicebox: Voicebox3D

@export var timeout := 5.0

var _in_flight_msg: Dictionary[int, String] = {}

@onready var _chats: Control = %Chats
@onready var _nm := NetworkManager.get_singleton()
@onready var _cm := ChatManager.get_singleton()


func _ready():
	super()
	if _nm.is_active and fumo.peer == 0:
		_cm.chat_req.connect(_on_chat_req)
		_cm.chat_ack.connect(_on_chat_ack)
	else:
		_cm.chat.connect(_on_chat)


func _on_chat_req(id: int, content: String):
	_in_flight_msg[id] = content


func _on_chat_ack(id: int, status: ChatManager.ChatStatus):
	if id not in _in_flight_msg:
		return

	var msg: String = _in_flight_msg[id]
	_read(msg)
	_in_flight_msg.erase(id)


func _on_chat(_sender: String, peer: int, content: String):
	if peer != fumo.peer:
		return

	_read(content)


func _read(msg: String):
	var bubble: ChatBubble = _CHAT_BUBBLE.instantiate()
	bubble.voicebox = voicebox
	_chats.add_child(bubble)
	await voicebox.read(msg, bubble.on_token)
	await get_tree().create_timer(timeout).timeout
	bubble.queue_free()
