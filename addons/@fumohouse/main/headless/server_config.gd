extends Resource

## The address for the server to bind to, or [code]*[/code] for any address.
@export var address := "*"
## The port for the server to listen on.
@export var port := 50103
## Password required for players to join, or empty if no password is required.
@export var password := ""
## Maximum number of players to allow.
@export var max_players := 20

## The world to load.
@export var world := WorldManager.DEFAULT_WORLD


func load_config(cfg: ConfigFile):
	address = cfg.get_value("server", "address", address)
	port = cfg.get_value("server", "port", port)
	password = cfg.get_value("server", "password", password)
	max_players = cfg.get_value("server", "max_players", max_players)

	world = cfg.get_value("world", "world", world)


func save_config(cfg: ConfigFile):
	cfg.set_value("server", "address", address)
	cfg.set_value("server", "port", port)
	cfg.set_value("server", "password", password)
	cfg.set_value("server", "max_players", max_players)

	cfg.set_value("world", "world", world)
