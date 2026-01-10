@abstract class_name NetworkPacket
extends RefCounted
## Represents a single message sent using [NetworkManager]. Contains an
## optional binary payload.

## The identifier of this packet. A string of bytes starting with any number of
## [code]0x80[/code] to [code]0xFF[/code] and ending with [code]0x00[/code] to
## [code]0x7F[/code].
var id: PackedByteArray = []

## The display name of this packet.
var display_name := ""

## Transfer mode to use for this packet.
var mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
## Channel to use for this packet.
var channel := 0


## Serialize/deserialize this packet's body.
func _serde(serde: SerDe):
	pass
