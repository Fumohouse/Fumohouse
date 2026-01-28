@tool
extends RefCounted
## Class for exporting a module as a PCK file.


## Exports the given [param modules] as PCKs. The resulting PCKs will be placed
## in [param out_path] as [code]modules/@scope/name.pck[/code].
static func export(modules: PackedStringArray, platform: String, out_path: String):
	var temp_dir_hnd := DirAccess.create_temp("fumohouse_export")
	var temp_dir := temp_dir_hnd.get_current_dir()

	var zip_path := temp_dir.path_join("master.zip")
	if _export_master_zip(platform, zip_path) != OK:
		return

	# Trim output and convert to PCK
	var zip := ZIPReader.new()
	var err := zip.open(zip_path)
	if err != OK:
		push_error("Failed to open master zip %s." % [zip_path])
		return

	for module in modules:
		var name_split: PackedStringArray = module.split("/")
		var out_dir := out_path.path_join("modules").path_join(name_split[0])
		DirAccess.make_dir_recursive_absolute(out_dir)
		_export_module_from_zip(module, zip, temp_dir, out_dir.path_join(name_split[1]) + ".pck")


## Exports the base package ([code]@fumohouse/base[/code] and the Godot
## executable). The resulting executable and PCK will be placed in
## [param out_path].
static func export_base_package(platform: String, out_path: String):
	var files := _scan_resources("res://addons/@fumohouse/base")

	# Construct export configuration, leaving most things default
	# https://github.com/godotengine/godot/blob/master/editor/export/editor_export.cpp
	var export_cfg := ConfigFile.new()
	export_cfg.set_value("preset.0", "name", platform)
	export_cfg.set_value("preset.0", "platform", platform)
	export_cfg.set_value("preset.0", "runnable", false)
	export_cfg.set_value("preset.0", "export_filter", "resources")
	export_cfg.set_value("preset.0", "export_files", files)
	export_cfg.set_value(
		"preset.0", "include_filter", "COPYRIGHT.txt, addons/@fumohouse/base/plugin.cfg"
	)
	export_cfg.set_value("preset.0", "exclude_filter", "")
	export_cfg.set_value("preset.0.options", "DUMMY", "DUMMY")

	if platform == "macOS":
		export_cfg.set_value(
			"preset.0.options", "application/bundle_identifier", "house.fumo.Fumohouse"
		)
	else:
		export_cfg.set_value("preset.0.options", "DUMMY", "DUMMY")

	var err := export_cfg.save("res://export_presets.cfg")
	if err != OK:
		push_error("Failed to save export preset configuration.")
		return err

	# Remove reference to all modules from the exported project.binary
	var plugins_backup: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled")
	ProjectSettings.set_setting("editor_plugins/enabled", null)
	ProjectSettings.save()

	var exe_name: String
	if platform.contains("Windows"):
		exe_name = "Fumohouse.exe"
	elif platform == "macOS":
		exe_name = "Fumohouse.app"
	else:
		exe_name = "Fumohouse"

	# Run export command to ZIP
	var exit_code: int = OS.execute(
		OS.get_executable_path(),
		["--headless", "--export-release", platform, out_path.path_join(exe_name)]
	)

	# Restore project settings
	ProjectSettings.set_setting("editor_plugins/enabled", plugins_backup)
	ProjectSettings.save()

	if exit_code != 0:
		push_error("Godot exited with error code %d." % [exit_code])
		return FAILED

	return OK


## Export everything in the project to a temporary ZIP file. The files can then
## be used to create individual module PCKs.
static func _export_master_zip(platform: String, zip_path: String) -> Error:
	var include_filter: PackedStringArray = ["*/COPYRIGHT.txt", "*/plugin.cfg"]
	Modules.scan_modules()
	for module in Modules.get_modules():
		for glob in module.additional_files:
			include_filter.push_back("res://addons".path_join(module.name).path_join(glob))

	var export_cfg := ConfigFile.new()
	export_cfg.set_value("preset.0", "name", platform)
	export_cfg.set_value("preset.0", "platform", platform)
	export_cfg.set_value("preset.0", "runnable", false)
	export_cfg.set_value("preset.0", "export_filter", "all_resources")
	export_cfg.set_value("preset.0", "include_filter", ", ".join(include_filter))
	export_cfg.set_value("preset.0", "exclude_filter", "")
	export_cfg.set_value("preset.0.options", "DUMMY", "DUMMY")

	var err := export_cfg.save("res://export_presets.cfg")
	if err != OK:
		push_error("Failed to save export preset configuration.")
		return err

	# Run export command to ZIP
	var exit_code: int = OS.execute(
		OS.get_executable_path(), ["--headless", "--export-pack", platform, zip_path]
	)
	if exit_code != 0:
		push_error("Godot exited with error code %d." % [exit_code])
		return FAILED

	return OK


static func _export_module_from_zip(
	module: String, zip: ZIPReader, temp_dir: String, out_path: String
):
	var pak := PCKPacker.new()
	pak.pck_start(out_path)

	var zip_contents := zip.get_files()
	zip_contents.sort()  # just in case
	var zip_module_prefix := "addons".path_join(module) + "/"

	var add_file := func(archive_path: String):
		var temp_file_path := temp_dir.path_join("extract").path_join(archive_path)
		DirAccess.make_dir_recursive_absolute(temp_file_path.get_base_dir())

		var temp_file := FileAccess.open(temp_file_path, FileAccess.WRITE)
		if not temp_file:
			push_error("Failed to open temporary file: %s." % [temp_file_path])
			return

		# FIXME: This is braindead
		var buf: PackedByteArray = zip.read_file(archive_path)
		temp_file.store_buffer(buf)
		temp_file.close()

		pak.add_file(archive_path, temp_file_path)

	# Trim contents
	for file in zip_contents:
		if not file.begins_with(zip_module_prefix):
			continue

		add_file.call(file)

		# Add referenced files in .godot/
		if file.ends_with(".remap") or file.ends_with(".import"):
			var cfg := ConfigFile.new()
			cfg.parse(zip.read_file(file).get_string_from_utf8())

			var remap_names: PackedStringArray = ["path", "path.s3tc", "path.etc2"]
			for key in remap_names:
				var remap_path: String = cfg.get_value("remap", key, "")
				if not remap_path.is_empty() and not remap_path.begins_with(zip_module_prefix):
					add_file.call(remap_path.trim_prefix("res://"))

	# Force exported files:
	# https://github.com/godotengine/godot/blob/08e6cd181f98f9ca3f58d89af0a54ce3768552d3/editor/export/editor_export_platform.cpp#L1053-L1077

	# UID cache
	# https://github.com/godotengine/godot/blob/08e6cd181f98f9ca3f58d89af0a54ce3768552d3/core/io/resource_uid.cpp#L277-L312
	# Format:
	# num_entries: i32
	# entries[num_entries]:
	# - id: i64
	# - path_len: i32
	# - path: char[path_len] (not null terminated)
	var uid_cache: PackedByteArray = zip.read_file(".godot/uid_cache.bin")
	var uid_num_entries := uid_cache.decode_s32(0)
	var new_uid_cache: PackedByteArray = []
	new_uid_cache.resize(4)

	var uid_read_ofs := 4
	var uid_new_num_entries := 0
	var uid_write_ofs := 4  # skip num_entries for now

	for i in uid_num_entries:
		var id := uid_cache.decode_s64(uid_read_ofs)
		uid_read_ofs += 8
		var path_len := uid_cache.decode_s32(uid_read_ofs)
		uid_read_ofs += 4
		var path: PackedByteArray = uid_cache.slice(uid_read_ofs, uid_read_ofs + path_len)
		uid_read_ofs += path_len

		if path.get_string_from_utf8().trim_prefix("res://").begins_with(zip_module_prefix):
			new_uid_cache.resize(new_uid_cache.size() + 8 + 4)
			new_uid_cache.encode_s64(uid_write_ofs, id)
			uid_write_ofs += 8
			new_uid_cache.encode_s32(uid_write_ofs, path_len)
			uid_write_ofs += 4
			new_uid_cache.append_array(path)
			uid_write_ofs += path_len
			uid_new_num_entries += 1

	new_uid_cache.encode_s32(0, uid_new_num_entries)

	var temp_uid_cache_path = temp_dir.path_join("uid_cache.bin")
	var temp_uid_cache := FileAccess.open(temp_uid_cache_path, FileAccess.WRITE)
	temp_uid_cache.store_buffer(new_uid_cache)
	temp_uid_cache.close()
	pak.add_file(".godot/uid_cache.bin", temp_uid_cache_path)

	# Global class cache
	var global_class_cache := ConfigFile.new()
	global_class_cache.parse(
		zip.read_file(".godot/global_script_class_cache.cfg").get_string_from_utf8()
	)

	var new_list: Array[Dictionary] = []
	for item in global_class_cache.get_value("", "list"):
		if item["path"].begins_with("res://" + zip_module_prefix):
			new_list.push_back(item)
	global_class_cache.set_value("", "list", new_list)

	var temp_global_class_cache_path = temp_dir.path_join("global_script_class_cache.cfg")
	global_class_cache.save(temp_global_class_cache_path)
	pak.add_file(".godot/global_script_class_cache.cfg", temp_global_class_cache_path)

	# TODO: Extension list

	pak.flush()


static func _scan_resources(path: String) -> PackedStringArray:
	var res: PackedStringArray = []
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Failed to read directory: %s." % [path])
		return res

	dir.list_dir_begin()

	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var full_path := path.path_join(file_name)

		if dir.current_is_dir():
			res.append_array(_scan_resources(full_path))
		elif ResourceLoader.exists(full_path):
			res.push_back(full_path)

		file_name = dir.get_next()

	return res
