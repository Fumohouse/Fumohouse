extends Command


func _init():
	name = &"say"
	CommandRegistry.get_singleton().register_command(self)


func _run(args: PackedStringArray, rest: String) -> CommandResult:
	if NetworkManager.get_singleton().is_server:
		ChatManager.get_singleton().send_system_message("Server", 0, rest)
	else:
		ChatManager.get_singleton().send_chat(rest)

	return null
