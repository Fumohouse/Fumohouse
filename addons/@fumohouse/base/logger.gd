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

const LOG_SCOPE := "Logger"
const LOG_DIR := "user://logs"

## The minimum level to log.
var log_level: LogType

var _os_logger := FumohouseLogger.new()
var _log_file: FileAccess = null
var _max_old_logs: int = 4


func _enter_tree():
	OS.add_logger(_os_logger)
	log_level = LogType.DEBUG if OS.is_debug_build() else LogType.INFO

	if OS.has_feature("dedicated_server"):
		_max_old_logs = -1

	_init_log_file()


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

	_os_logger.disable = true
	print(body)
	_os_logger.disable = false
	if _log_file:
		_log_file.store_line(body)
		_log_file.flush()
	log.emit(msg, scope, type, body)


func _init_log_file():
	if DirAccess.dir_exists_absolute(LOG_DIR):
		# Rotate logs
		var dir := DirAccess.open(LOG_DIR)
		if not dir:
			error("Failed to open log directory.", LOG_SCOPE)
			return

		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		var files: PackedStringArray = []
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".log"):
				files.push_back(file_name)
			file_name = dir.get_next()

		if _max_old_logs >= 0 and files.size() > _max_old_logs:
			files.sort()
			for file in files.slice(0, files.size() - _max_old_logs):
				DirAccess.remove_absolute(LOG_DIR.path_join(file))
	else:
		if DirAccess.make_dir_absolute(LOG_DIR) != OK:
			error("Failed to create log directory.", LOG_SCOPE)
			return

	var file_path := LOG_DIR.path_join(
		(
			"%s_%d.log"
			% [Time.get_datetime_string_from_system().replace(":", "-"), OS.get_process_id()]
		)
	)
	_log_file = FileAccess.open(file_path, FileAccess.WRITE)
	if not _log_file:
		error("Failed to open log file: %s" % file_path, LOG_SCOPE)
		return

	_log_file.store_line("Fumohouse - https://fumo.house")

	var ver_info: Dictionary = Engine.get_version_info()
	(
		_log_file
		. store_line(
			(
				"Godot Engine v%d.%d.%d.%s.%s.%s"
				% [
					ver_info["major"],
					ver_info["minor"],
					ver_info["patch"],
					ver_info["status"],
					ver_info["build"],
					ver_info["hash"].substr(0, 8),
				]
			)
		)
	)

	_log_file.store_line("OS: %s (%s)" % [OS.get_name(), Engine.get_architecture_name()])

	(
		_log_file
		. store_line(
			(
				"CPU: %s (%s)"
				% [
					OS.get_processor_name(),
					OS.get_processor_count(),
				]
			)
		)
	)

	(
		_log_file
		. store_line(
			(
				"GPU: %s - %s - DeviceType: %d"
				% [
					RenderingServer.get_video_adapter_vendor(),
					RenderingServer.get_video_adapter_name(),
					RenderingServer.get_video_adapter_type(),
				]
			)
		)
	)

	(
		_log_file
		. store_line(
			(
				"Renderer: %s, version %s"
				% [
					ProjectSettings.get_setting(&"rendering/renderer/rendering_method"),
					RenderingServer.get_video_adapter_api_version(),
				]
			)
		)
	)

	_log_file.store_string("\n")


class FumohouseLogger:
	extends Logger

	var disable := false
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
		if disable:
			return

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
		if disable:
			return

		var scope := "Godot" if override_scope.is_empty() else override_scope
		Log._log(message, scope, LogType.WARN if error else LogType.INFO)
