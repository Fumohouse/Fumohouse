extends RefCounted
## Implementation of the export CLI.

const LOG_SCOPE := "Export"
const ModuleExporter := preload("module_exporter.gd")

const _PLATFORMS := {
	"linux": "Linux",
	"windows": "Windows Desktop",
	"macos": "macOS",
}


static func run(argd: Dictionary[StringName, String], argv: PackedStringArray) -> int:
	if "platform" not in argd:
		Log.error(
			(
				"Provide a platform using --platform (supported platforms: %s)"
				% ", ".join(_PLATFORMS.keys())
			),
			LOG_SCOPE
		)
		return 1

	var platform_name = _PLATFORMS.get(argd["platform"])
	if not platform_name:
		Log.error("Invalid platform name '%s'." % argd["platform"], LOG_SCOPE)
		return 1

	var out_path = argd.get("out")
	if not out_path:
		Log.error("Specify an output path with --out.", LOG_SCOPE)
		return 1

	var modules: PackedStringArray = []
	var include: PackedStringArray = argd.get("include", "").split(",")
	var exclude: PackedStringArray = argd.get("exclude", "").split(",")

	if include.size() == 1 and include[0] == "":
		include = []
	if exclude.size() == 1 and exclude[0] == "":
		exclude = []

	for mod in Modules.get_modules():
		if mod.name == &"@fumohouse/base":
			continue

		if (
			include.size() == 0 and exclude.size() == 0
			or include.size() > 0 and include.has(mod.name)
			or exclude.size() > 0 and not exclude.has(mod.name)
		):
			modules.append(mod.name)

	var server = "server" in argd

	Log.info("Platform: %s" % platform_name, LOG_SCOPE)
	Log.info("Server mode: %s" % server, LOG_SCOPE)

	Log.info("Exporting base package...", LOG_SCOPE)
	ModuleExporter.export_base_package(platform_name, out_path, server)

	Log.info("Exporting modules %s..." % ", ".join(modules), LOG_SCOPE)
	ModuleExporter.export(modules, platform_name, out_path, server)

	return 0
