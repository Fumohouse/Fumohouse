class_name CommandRegistry
extends Node
## Singleton for storing and running [Command]s.

var _commands: Dictionary[StringName, Command] = {}


static func get_singleton() -> CommandRegistry:
	return Modules.get_singleton(&"CommandRegistry") as CommandRegistry


## Register the given [param command].
func register_command(command: Command):
	_commands[command.name] = command
	for alias in command.aliases:
		_commands[alias] = command


## Get the command corresponding to the given [param command] string.
func get_command(command: String) -> Command:
	var command_name: StringName = command.substr(0, command.find(" "))
	return _commands.get(command_name)


## Run the given [param command], passed as an entire string to be parsed.  Can
## return [code]null[/code].
func run(command: String) -> Command.CommandResult:
	var command_name: StringName = command.substr(0, command.find(" "))
	var rest := command.substr(command_name.length() + 1)
	var args_raw := rest.split(" ")
	var args_normalized: PackedStringArray = []

	for arg in args_raw:
		args_normalized.push_back(arg.strip_edges())

	var cmd: Command = _commands.get(command_name)
	if cmd:
		return cmd._run(args_normalized, rest)

	var res := Command.CommandResult.new()
	res.output = "Command not found: %s" % command_name
	return res
