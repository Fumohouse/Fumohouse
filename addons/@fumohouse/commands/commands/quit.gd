extends Command


func _init():
	name = &"quit"
	aliases = ["stop"]
	CommandRegistry.get_singleton().register_command(self)


func _run(args: PackedStringArray, rest: String) -> CommandResult:
	QuitManager.get_singleton().quit()
	return null
