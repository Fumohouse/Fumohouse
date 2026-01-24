extends Node
## Logger class.

## Fired when a log message is received.
signal log(msg: String, scope: String, type: LogType, default_body: String)

enum LogType {
	DEBUG = 0,
	INFO,
	WARN,
	ERROR,
}

## The minimum level to log.
var log_level: LogType

var _os_logger := FumohouseLogger.new()


func _enter_tree():
	OS.add_logger(_os_logger)
	log_level = LogType.DEBUG if OS.is_debug_build() else LogType.INFO


## Debug log message.
func debug(msg: String, scope := ""):
	_log(msg, scope, LogType.DEBUG)


## Informational log message.
func info(msg: String, scope := ""):
	_log(msg, scope, LogType.INFO)


## Warning log message. [method @GlobalScope.push_warning] is called
## automatically.
func warn(msg: String, scope := ""):
	_os_logger.override_scope = scope
	push_warning(msg)
	_os_logger.override_scope = ""


## Error log message. [method @GlobalScope.push_error] is called automatically.
func error(msg: String, scope := ""):
	_os_logger.override_scope = scope
	push_error(msg)
	_os_logger.override_scope = ""


func _log(msg: String, scope := "", type: LogType = LogType.INFO):
	if type < log_level:
		return

	var body := ""

	if OS.is_debug_build():
		body += "[%d] " % OS.get_process_id()

	body += "%s > " % Time.get_datetime_string_from_system()
	if not scope.is_empty():
		body += "[%s] " % scope
	body += "[%s] " % LogType.keys()[type]

	var line_idx: int = msg.find("\n")
	if line_idx == -1:
		body += msg
	else:
		body += msg.substr(0, line_idx) + "\n" + msg.substr(line_idx + 1).indent("    ")

	print(body)
	log.emit(msg, scope, type, body)


class FumohouseLogger:
	extends Logger

	var override_scope := ""

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
	):
		var msg := (
			"%s:%d @ %s(): %s" % [file, line, function, rationale if code.is_empty() else code]
		)
		if not script_backtraces.is_empty():
			for bt in script_backtraces:
				msg += "\n" + str(bt)

		var scope := "Godot" if override_scope.is_empty() else override_scope
		Log._log(
			msg, scope, LogType.WARN if error_type == Logger.ERROR_TYPE_WARNING else LogType.ERROR
		)

	func _log_message(message: String, error: bool):
		var scope := "Godot" if override_scope.is_empty() else override_scope
		Log._log(message, scope, LogType.WARN if error else LogType.INFO)
