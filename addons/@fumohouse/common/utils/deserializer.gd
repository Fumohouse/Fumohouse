class_name Deserializer
extends SerDe
## Class for deserializing values from a [PackedByteArray].


func buffer(buf: PackedByteArray) -> PackedByteArray:
	var sz: int = buf.size()
	_ensure_capacity(sz)

	for i in sz:
		buf[i] = _buffer[_pos + i]

	_pos += sz
	return buf


func varuint(value := 0) -> int:
	var res := 0
	var pos := 0
	var curr: int = u8(0)
	while curr & 0x80:
		res |= (curr & 0x7F) << pos
		curr = u8(0)
		pos += 7

	res |= (curr & 0x7F) << pos

	return res


func u8(value := 0) -> int:
	_ensure_capacity(1)
	var ret: int = _buffer.decode_u8(_pos)
	_pos += 1
	return ret


func s8(value := 0) -> int:
	_ensure_capacity(1)
	var ret: int = _buffer.decode_s8(_pos)
	_pos += 1
	return ret


func u16(value := 0) -> int:
	_ensure_capacity(2)
	var ret: int = _buffer.decode_u16(_pos)
	_pos += 2
	return ret


func s16(value := 0) -> int:
	_ensure_capacity(2)
	var ret: int = _buffer.decode_s16(_pos)
	_pos += 2
	return ret


func u32(value := 0) -> int:
	_ensure_capacity(4)
	var ret: int = _buffer.decode_u32(_pos)
	_pos += 4
	return ret


func s32(value := 0) -> int:
	_ensure_capacity(4)
	var ret: int = _buffer.decode_s32(_pos)
	_pos += 4
	return ret


func u64(value := 0) -> int:
	_ensure_capacity(8)
	var ret: int = _buffer.decode_u64(_pos)
	_pos += 8
	return ret


func s64(value := 0) -> int:
	_ensure_capacity(8)
	var ret: int = _buffer.decode_s64(_pos)
	_pos += 8
	return ret


func f16(value := 0.0) -> float:
	_ensure_capacity(2)
	var ret: float = _buffer.decode_half(_pos)
	_pos += 2
	return ret


func f32(value := 0.0) -> float:
	_ensure_capacity(4)
	var ret: float = _buffer.decode_float(_pos)
	_pos += 4
	return ret


func f64(value := 0.0) -> float:
	_ensure_capacity(8)
	var ret: float = _buffer.decode_double(_pos)
	_pos += 8
	return ret


func str(value := String()) -> String:
	var size: int = varuint(0)
	var buf := PackedByteArray()
	buf.resize(size)
	buffer(buf)
	return buf.get_string_from_utf8()


func variant(value: Variant = null) -> Variant:
	assert(_buffer.has_encoded_var(_pos), "No variant at this position")
	var ret: Variant = _buffer.decode_var(_pos)
	_pos += _buffer.decode_var_size(_pos)
	return ret


func _ensure_capacity(capacity: int):
	assert(_buffer.size() >= _pos + capacity, "Unexpected end of buffer.")
