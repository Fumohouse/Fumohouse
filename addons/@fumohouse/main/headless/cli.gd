extends Node

const LOG_SCOPE := "Server"
const ServerConfig := preload("server_config.gd")

var _input_thread: Thread


func _ready():
	var dir := "." if OS.is_debug_build() else OS.get_executable_path().get_base_dir()
	_stupid_ascii_art(dir)

	var config_path := dir.path_join("server_config.ini")
	var config := ServerConfig.new()

	var ini := ConfigFile.new()
	if FileAccess.file_exists(config_path):
		ini.load(config_path)
		config.load_config(ini)
	else:
		Log.info("Writing default server config...", LOG_SCOPE)
		config.save_config(ini)
		ini.save(config_path)

	_input_thread = Thread.new()
	_input_thread.start(_process_input)

	var err := await WorldManager.get_singleton().start_multiplayer_server(
		config.world, config.port, config.address, config.password, config.max_players
	)

	if err != OK:
		Log.info("Failed to start server: %s (%d)" % [error_string(err), err], LOG_SCOPE)
		QuitManager.get_singleton().quit()


func _exit_tree():
	_input_thread.wait_to_finish()


func _stupid_ascii_art(dir: String):
	Log.info("                     .#.")
	Log.info("                   ####***-%@@@.")
	Log.info("           .       ###*@@@@@%@@@")
	Log.info("         .        -##@@@#++.                _____                      _")
	(
		Log
		. info(
			"        ..        .@@@#+++=                |  ___|   _ _ __ ___   ___ | |__   ___  _   _ ___  ___"
		)
	)
	(
		Log
		. info(
			"        @       :@@@**+++=-                | |_ | | | | '_ ` _ \\ / _ \\| '_ \\ / _ \\| | | / __|/ _ \\"
		)
	)
	(
		Log
		. info(
			"       @      -@@*    . .                  |  _|| |_| | | | | | | (_) | | | | (_) | |_| \\__ \\  __/"
		)
	)
	(
		Log
		. info(
			"       @    @@@:  * .++.:                  |_|   \\__,_|_| |_| |_|\\___/|_| |_|\\___/ \\__,_|___/\\___|"
		)
	)
	Log.info("      .@ .@@@.      ++=:.-")
	Log.info(
		(
			"       @@@:       +.+=== ::                Dedicated Server • %s"
			% DistConfig.get_build_string()
		)
	)
	Log.info("                   .:==:                   Server directory: %s" % dir)
	Log.info("                  ==.")


func _process_input():
	while true:
		var line := OS.read_string_from_stdin().strip_edges()
		var cmd := line.substr(0, line.find(" "))
		var rest := line.substr(cmd.length() + 1)
		var args := rest.split(" ")

		if cmd == "stop":
			QuitManager.get_singleton().quit.call_deferred()
			break
		elif cmd == "say":
			ChatManager.get_singleton().send_system_message.call_deferred("Server", 0, rest)
