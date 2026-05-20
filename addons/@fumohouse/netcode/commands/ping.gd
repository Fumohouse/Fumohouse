extends Command


func _init():
	name = &"ping"
	CommandRegistry.get_singleton().register_command(self)


func _run(args: PackedStringArray, rest: String) -> CommandResult:
	var lines: PackedStringArray = ["Current ping measures:"]
	var nm := NetworkManager.get_singleton()

	for peer in nm.get_peers():
		lines.push_back("%s - %.2fms\n" % [nm.get_peer_identity(peer), nm.get_peer_rtt(peer)])

	var res := CommandResult.new()
	res.output = "\n".join(lines)
	return res
