@abstract class_name SerDe
extends RefCounted
## Abstract class for serializing or deserializing values to/from a
## [PackedByteArray].

## Current read/write position.
var pos: int:
	get:
		return _pos

var _buffer: PackedByteArray = []
var _pos := 0


func _init(buffer: PackedByteArray):
	_buffer = buffer


## Move the write/read head to [param pos].
func seek(pos: int):
	_pos = pos


## Returns whether the end of the buffer has been reached.
func eof() -> bool:
	return _pos == _buffer.size()


## Encode/decode a boolean.
func boolean(value: bool) -> bool:
	return bool(u8(value))


## Encode/decode a raw buffer. Size is determined by the input buffer.
## On deserialize, writes data into the input buffer.
func buffer(buf: PackedByteArray) -> PackedByteArray:
	return []


## Encode/decode a raw buffer. Size is stored in the input/output buffer.
## On deserialize, writes data into the input buffer.
func sized_buffer(buf: PackedByteArray) -> PackedByteArray:
	buf.resize(varuint(buf.size()))
	buffer(buf)
	return buf


## Encode/decode a variable-length unsigned integer, where the most significant
## bit of each byte is 1 if and only if there is another byte to consider, and
## the least significant 7 bits encode the value. The least significant bits are
## written first.
func varuint(value: int) -> int:
	return 0


## Encode/decode a variable-length signed integer, using [method varuint] and
## ZigZag encoding.
func varsint(value: int) -> int:
	var val_enc: int = -2 * value - 1 if value < 0 else 2 * value
	var val_res: int = varuint(val_enc)
	return val_res / 2 if val_res % 2 == 0 else -val_res / 2 - 1


## Encode/decode an unsigned 8-bit integer.
func u8(value: int) -> int:
	return 0


## Encode/decode a signed 8-bit integer.
func s8(value: int) -> int:
	return 0


## Encode/decode an unsigned 16-bit integer.
func u16(value: int) -> int:
	return 0


## Encode/decode a signed 16-bit integer.
func s16(value: int) -> int:
	return 0


## Encode/decode an unsigned 32-bit integer.
func u32(value: int) -> int:
	return 0


## Encode/decode a signed 32-bit integer.
func s32(value: int) -> int:
	return 0


## Encode/decode an unsigned 64-bit integer.
func u64(value: int) -> int:
	return 0


## Encode/decode a signed 64-bit integer.
func s64(value: int) -> int:
	return 0


## Encode/decode a 16-bit floating point number.
func f16(value: float) -> float:
	return 0.0


## Encode/decode a 32-bit floating point number.
func f32(value: float) -> float:
	return 0.0


## Encode/decode a 64-bit floating point number.
func f64(value: float) -> float:
	return 0.0


## Encode/decode a [Vector3].
func vector3(value: Vector3) -> Vector3:
	return Vector3(f64(value.x), f64(value.y), f64(value.z))


## Encode/decode a [Basis].
func basis(value: Basis) -> Basis:
	return Basis(vector3(value.x), vector3(value.y), vector3(value.z))


## Encode/decode a [Transform3D].
func transform_3d(value: Transform3D) -> Transform3D:
	return Transform3D(basis(value.basis), vector3(value.origin))


## Encode/decode a UTF-8 string.
func str(value: String) -> String:
	return ""


## Encode/decode a variant.
func variant(value: Variant) -> Variant:
	return null


## Ensure the buffer is at least [member _pos] plus [param capacity] large.
func _ensure_capacity(capacity: int):
	return
