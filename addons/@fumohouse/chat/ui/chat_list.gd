extends ScrollContainer

const _CHAT_SCENE := preload("chat_msg.tscn")
const _MAX_CHATS := 100
const _PENDING_COLOR := Color("#9f9f9f")

var _pool: Array[RichTextLabel] = []
var _in_flight_lbl: Dictionary[int, RichTextLabel] = {}
var _in_flight_msg: Dictionary[int, String] = {}
var _lbl_in_flight: Dictionary[RichTextLabel, int] = {}

@onready var _vbox: VBoxContainer = $VBoxContainer
@onready var _cm := ChatManager.get_singleton()
@onready var _nm := NetworkManager.get_singleton()


func _ready():
	_cm.chat.connect(_on_chat)
	_cm.chat_req.connect(_on_chat_req)
	_cm.chat_ack.connect(_on_chat_ack)

	for i in _MAX_CHATS:
		_pool.push_back(_CHAT_SCENE.instantiate())


func _on_chat(sender: String, peer: int, content: String):
	_push_chat(_add_label(), sender, peer, content)


func _on_chat_req(id: int, content: String):
	var lbl: RichTextLabel = _push_chat(
		_add_label(), _nm.local_identity, _nm.local_peer_id, content, true
	)
	_in_flight_lbl[id] = lbl
	_in_flight_msg[id] = content
	_lbl_in_flight[lbl] = id


func _on_chat_ack(id: int, status: ChatManager.ChatStatus):
	if id not in _in_flight_lbl:
		return

	var lbl: RichTextLabel = _in_flight_lbl[id]
	var msg: String = _in_flight_msg[id]

	_push_chat(lbl, _nm.local_identity, _nm.local_peer_id, msg)

	_lbl_in_flight.erase(lbl)


func _push_chat(
	lbl: RichTextLabel, sender: String, peer: int, content: String, pending := false
) -> RichTextLabel:
	lbl.clear()

	if not sender.is_empty():
		lbl.push_color(Color.from_hsv((peer % 360) / 360.0, 0.5, 1.0))
		lbl.append_text("[%s]" % sender)
		lbl.pop()
		lbl.append_text(" ")

	if pending:
		lbl.push_color(_PENDING_COLOR)
	lbl.append_text(content)
	if pending:
		lbl.pop()

	return lbl


func _add_label() -> RichTextLabel:
	var lbl: RichTextLabel
	if _pool.is_empty():
		lbl = _vbox.get_child(0)
		_vbox.move_child(lbl, _vbox.get_child_count() - 1)
		var id_in_flight: int = _lbl_in_flight.get(lbl, -1)
		if id_in_flight >= 0:
			_in_flight_lbl.erase(id_in_flight)
			_in_flight_msg.erase(id_in_flight)
			_lbl_in_flight.erase(lbl)
	else:
		lbl = _pool.pop_back()
		_vbox.add_child(lbl)

	# ?
	set_deferred.call_deferred(&"scroll_vertical", get_v_scroll_bar().max_value)
	return lbl
