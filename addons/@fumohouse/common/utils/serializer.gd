class_name Serializer
extends SerDe
## Class for serializing values to a [PackedByteArray].


## Returns the underlying buffer truncated to the current seek position.
func to_buffer() -> PackedByteArray:
	return _buffer.slice(0, _pos)


## Writes the contents of the given [param serializer] to this one.
func ser(serializer: Serializer):
	_ensure_capacity(serializer.pos)

	for i in serializer.pos:
		_buffer[_pos + i] = serializer._buffer[i]

	_pos += serializer.pos


func buffer(buf: PackedByteArray) -> PackedByteArray:
	var sz: int = buf.size()
	_ensure_capacity(sz)

	for i in sz:
		_buffer[_pos + i] = buf[i]

	_pos += sz
	return buf


func varuint(value: int) -> int:
	if value == 0:
		u8(0)
		return value

	var curr := value
	while curr > 0:
		u8(curr if curr <= 127 else (curr & 0b1111111) | 0x80)
		curr >>= 7

	return value


func u8(value: int) -> int:
	_ensure_capacity(1)
	_buffer.encode_u8(_pos, value)
	_pos += 1
	return value


func s8(value: int) -> int:
	_ensure_capacity(1)
	_buffer.encode_s8(_pos, value)
	_pos += 1
	return value


func u16(value: int) -> int:
	_ensure_capacity(2)
	_buffer.encode_u16(_pos, value)
	_pos += 2
	return value


func s16(value: int) -> int:
	_ensure_capacity(2)
	_buffer.encode_s16(_pos, value)
	_pos += 2
	return value


func u32(value: int) -> int:
	_ensure_capacity(4)
	_buffer.encode_u32(_pos, value)
	_pos += 4
	return value


func s32(value: int) -> int:
	_ensure_capacity(4)
	_buffer.encode_s32(_pos, value)
	_pos += 4
	return value


func u64(value: int) -> int:
	_ensure_capacity(8)
	_buffer.encode_u64(_pos, value)
	_pos += 8
	return value


func s64(value: int) -> int:
	_ensure_capacity(8)
	_buffer.encode_s64(_pos, value)
	_pos += 8
	return value


func f16(value: float) -> float:
	_ensure_capacity(2)
	_buffer.encode_half(_pos, value)
	_pos += 2
	return value


func f32(value: float) -> float:
	_ensure_capacity(4)
	_buffer.encode_float(_pos, value)
	_pos += 4
	return value


func f64(value: float) -> float:
	_ensure_capacity(8)
	_buffer.encode_double(_pos, value)
	_pos += 8
	return value


func str(value: String) -> String:
	var buf: PackedByteArray = value.to_utf8_buffer()
	_ensure_capacity(4 + buf.size())
	varuint(buf.size())
	buffer(buf)
	return value


func variant(value: Variant) -> Variant:
	var buf: PackedByteArray = var_to_bytes(value)
	buffer(buf)
	return value


func _ensure_capacity(capacity: int):
	var curr_size: int = _buffer.size()
	if curr_size >= _pos + capacity:
		return

	_buffer.resize(maxi(curr_size + capacity, curr_size * 2))
