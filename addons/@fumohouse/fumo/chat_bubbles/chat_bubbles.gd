extends "../character_billboard.gd"

const ChatBubble := preload("chat_bubble.gd")
const _CHAT_BUBBLE := preload("chat_bubble.tscn")

@export var fumo: Fumo
@export var voicebox: Voicebox3D

@export var timeout := 5.0

var _in_flight_msg: Dictionary[int, String] = {}

@onready var _chats: Control = %Chats
@onready var _typing_indicator: Control = %TypingIndicator
@onready var _nm := NetworkManager.get_singleton()
@onready var _cm := ChatManager.get_singleton()


func _ready():
	super()
	if _nm.is_active and fumo.peer == 0:
		_cm.chat_req.connect(_on_chat_req)
		_cm.chat_ack.connect(_on_chat_ack)
	else:
		_cm.chat.connect(_on_chat)
		_cm.chat_typing.connect(_on_typing)


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


func _on_typing(peer: int, typing: bool):
	if peer != fumo.peer:
		return

	_typing_indicator.visible = typing


func _read(msg: String):
	var bubble: ChatBubble = _CHAT_BUBBLE.instantiate()
	bubble.voicebox = voicebox
	_chats.add_child(bubble)
	_chats.move_child(bubble, -2)  # before typing indicator
	await voicebox.read(msg, bubble.on_token)
	await get_tree().create_timer(timeout).timeout
	bubble.queue_free()
