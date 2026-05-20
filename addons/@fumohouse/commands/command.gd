@abstract class_name Command
extends RefCounted
## Abstract class for commands.

## Canonical name of this commmand.
var name := &""
## List of aliases for this command.
var aliases: PackedStringArray = []


## Run the command with the given arguments. [param rest] is provided as a
## verbatim representation of all arguments for convenience. Can return
## [code]null[/code].
func _run(args: PackedStringArray, rest: String) -> CommandResult:
	return CommandResult.new()


## Class representing the result of running a command.
class CommandResult:
	extends RefCounted
	## String output of the command. Empty to print nothing.
	var output: String
