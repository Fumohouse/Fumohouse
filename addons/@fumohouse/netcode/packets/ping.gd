extends NetworkPacket
## Bidirectional: Heartbeat and latency test.

const ID: PackedByteArray = [0x04]

## Whether this is a response to a previous ping.
var pong := false
## Ping payload (e.g., time)
var payload := 0


func _init():
	id = ID
	display_name = "PING"


func _serde(serde: SerDe):
	pong = serde.boolean(pong)
	payload = serde.s64(payload)
