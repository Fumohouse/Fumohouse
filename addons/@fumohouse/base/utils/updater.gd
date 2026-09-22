extends Node
## Utilities for performing module download/updates.

## Emitted when the updater identifies the version of Fumohouse to be
## downloaded.
signal got_version(version: String, version_name: String)
## Emitted when the updater determines whether the base package is valid or not.
signal bp_validated(success: bool)
## Emitted when the updater determines which modules will be downloaded.
signal got_downloads(modules: PackedStringArray)
## Emitted when a module starts downloading.
signal download_start(mod: String)
## Emitted when a module finishes downloading.
signal download_complete(mod: String, success: bool)
## Emitted when a module starts extracting.
signal extract_started(mod: String)
## Emitted when a module finishes extracting.
signal extract_complete(mod: String, success: bool)

const LOG_SCOPE := "Updater"
const ENDPOINT := "https://git.seki.pw/api"
const PACKAGE_OWNER := "fumohouse"
const DL_CONCURRENCY := 4
const DL_DIR := "user://downloads/"

var package_name := ""
var is_supported: bool:
	get:
		return not package_name.is_empty()

var _pool: HTTPRequestPool
var _downloads: Dictionary[String, String] = {}


func _ready():
	var is_server := OS.has_feature("dedicated_server")
	var arch: String = Engine.get_architecture_name()
	match OS.get_name():
		"Linux":
			if arch == "x86_64":
				package_name = "fumohouse-linux-server" if is_server else "fumohouse-linux"
		"macOS":
			package_name = "fumohouse-macos-server" if is_server else "fumohouse-macos"
		"Windows":
			if arch == "x86_64":
				package_name = "fumohouse-windows-server" if is_server else "fumohouse-windows"

	if not is_supported:
		Log.warn("This platform does not support automatic module updates.", LOG_SCOPE)

	_pool = HTTPRequestPool.new()
	add_child(_pool)


## Start the update process. Return whether the update succeeded.
func start() -> bool:
	if package_name.is_empty():
		Log.error("Cannot start update. Updater is not supported.", LOG_SCOPE)
		return false
	Log.info("Starting updater...", LOG_SCOPE)

	# Identify latest version
	var version := await get_latest_version()
	if version.is_empty():
		return false
	Log.info("Latest Fumohouse version: %s" % version, LOG_SCOPE)

	var manifest := await get_manifest(version)
	if manifest.is_empty():
		return false

	got_version.emit(version, manifest.get("name"))

	# Check if base package is valid
	var pck_path := "Fumohouse.pck"
	match OS.get_name():
		"macOS":
			pck_path = "Fumohouse.app/Contents/Resources/Fumohouse.pck"

	var expected_godot_ver := manifest.get("godot_version")
	var actual_godot_ver := BaseUtils.get_engine_version_string()
	var expected_bp_hash: String = manifest.get("base_package", {}).get(pck_path, {}).get(
		"sha256", ""
	)
	var actual_bp_hash := BaseUtils.hash_file(BaseUtils.get_main_pck_path())

	if actual_godot_ver != expected_godot_ver or actual_bp_hash != expected_bp_hash:
		(
			Log
			. info(
				(
					"The base package is outdated. Expected Godot %s, got %s; expected base package hash '%s', got '%s'. Aborting..."
					% [expected_godot_ver, actual_godot_ver, expected_bp_hash, actual_bp_hash]
				),
				LOG_SCOPE
			)
		)
		bp_validated.emit(false)
		return false

	bp_validated.emit(true)

	# Identify modules to be downloaded
	var modules: Dictionary = manifest.get("modules", {})
	var existing_hashes: Dictionary[String, String] = hash_modules(modules.keys())

	var to_download: Dictionary[String, String] = {}
	for mod: String in modules:
		var ref_hash: String = modules[mod]["sha256"]
		var actual_hash: String = existing_hashes[mod]

		if ref_hash != actual_hash:
			Log.info(
				(
					"Queueing download of module %s due to hash mismatch (expected '%s', got '%s')."
					% [mod, ref_hash, actual_hash]
				),
				LOG_SCOPE
			)
			var url := (
				ENDPOINT
				+ (
					"/packages/%s/generic/%s/%s/%s.pck.gz"
					% [PACKAGE_OWNER, package_name, version, mod.replace("/", "-")]
				)
			)
			to_download[mod] = url

	got_downloads.emit(to_download.keys())

	# Download modules
	if to_download.is_empty():
		Log.info("All modules are up-to-date.", LOG_SCOPE)
		return true

	var err := DirAccess.make_dir_recursive_absolute(DL_DIR)
	if err != OK:
		Log.error("Failed to create download directory with error code %d." % err, LOG_SCOPE)
		return false

	var i := 0
	for mod in to_download:
		if i >= DL_CONCURRENCY:
			var res: Array = await download_complete
			if not res[1]:
				return false
			res = await extract_complete
			if not res[1]:
				return false

		download(mod, to_download[mod])
		i += 1

	i = 0
	while i < min(to_download.size(), DL_CONCURRENCY):
		var res: Array = await download_complete
		if not res[1]:
			return false
		res = await extract_complete
		if not res[1]:
			return false
		i += 1

	# Verifying
	var new_hashes: Dictionary[String, String] = hash_modules(modules.keys())
	var valid := true
	for mod: String in modules:
		var ref_hash: String = modules[mod]["sha256"]
		var actual_hash: String = new_hashes[mod]

		if ref_hash != actual_hash:
			Log.error(
				(
					"Download of module %s failed. Expected hash %s, got %s."
					% [mod, ref_hash, actual_hash]
				),
				LOG_SCOPE
			)
			valid = false

	if not valid:
		return false

	Log.info("Module update complete and verified.", LOG_SCOPE)
	return true


## Get the latest revision of Fumohouse. Asynchronous function returns the
## revision name or an empty string if the request was not successful.
func get_latest_version() -> String:
	if package_name.is_empty():
		Log.error("Cannot get latest version. Updater is not supported.", LOG_SCOPE)
		return ""

	var url := ENDPOINT + "/v1/packages/%s?q=%s" % [PACKAGE_OWNER, package_name]
	var res: HTTPRequestPool.Response = await _pool.request(url, [], HTTPClient.METHOD_GET, [])
	if res.result != HTTPRequest.RESULT_SUCCESS or res.status != 200:
		Log.error(
			"Version request failed with result %d, HTTP status %d" % [res.result, res.status],
			LOG_SCOPE
		)
		return ""

	var data: Array = JSON.parse_string(res.body.get_string_from_utf8())
	data.sort_custom(
		func(a: Dictionary, b: Dictionary): return a.get("id", -1.0) > b.get("id", -1.0)
	)
	for pkg in data:
		if pkg.get("name") == package_name:
			var version: String = pkg.get("version", "")
			if version.is_empty():
				Log.error("Unable to retrieve latest version from response body.", LOG_SCOPE)
			else:
				Log.info("Found latest release: %s" % pkg.get("html_url"), LOG_SCOPE)

			return version

	return ""


## Get the manifest file associated with [param version]. Returns an empty
## dictionary on failure.
func get_manifest(version: String) -> Dictionary:
	if package_name.is_empty():
		Log.error("Cannot get manifest. Updater is not supported.", LOG_SCOPE)
		return {}

	var url := (
		ENDPOINT
		+ "/packages/%s/generic/%s/%s/manifest.json" % [PACKAGE_OWNER, package_name, version]
	)
	var res: HTTPRequestPool.Response = await _pool.request(url, [], HTTPClient.METHOD_GET, [])
	if res.result != HTTPRequest.RESULT_SUCCESS or res.status != 200:
		Log.error(
			"Manifest request failed with result %d, HTTP status %d" % [res.result, res.status],
			LOG_SCOPE
		)
		return {}

	return JSON.parse_string(res.body.get_string_from_utf8())


## Get the SHA256 hash of the given modules.
func hash_modules(modules: PackedStringArray) -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}

	for mod in modules:
		var pak_path: String = Modules.PAK_DIR.path_join(mod + ".pck")
		out[mod] = BaseUtils.hash_file(pak_path)

	return out


## Download the given module to the download directory and extract it.
func download(module: String, url: String):
	Log.info("Downloading module %s..." % module, LOG_SCOPE)

	download_start.emit(module)
	var gz_path := DL_DIR.path_join(module.replace("/", "-") + ".pck.gz")
	_downloads[module] = gz_path
	var res: HTTPRequestPool.Response = await _pool.request(
		url, [], HTTPClient.METHOD_GET, [], gz_path
	)
	var success := res.result == HTTPRequest.RESULT_SUCCESS and res.status == 200
	if not success:
		Log.error(
			(
				"Module %s download failed with result %d, HTTP status %d"
				% [module, res.result, res.status]
			),
			LOG_SCOPE
		)

	download_complete.emit(module, success)
	if not success:
		return

	extract_started.emit(module)
	Log.info("Extracting module %s..." % module, LOG_SCOPE)

	var in_file := FileAccess.open(gz_path, FileAccess.READ)
	if not in_file:
		Log.error("Failed to open compressed module %s." % gz_path)
		extract_complete.emit(module, false)
		return

	var out_path := Modules.PAK_DIR.path_join(module + ".pck")
	var err := DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	if err != OK:
		Log.error("Failed to make directory for module with error code %d." % err, LOG_SCOPE)
		extract_complete.emit(module, false)
		return
	var out_file := FileAccess.open(out_path, FileAccess.WRITE)
	if not out_file:
		Log.error("Failed to open module extract path %s." % out_path, LOG_SCOPE)
		extract_complete.emit(module, false)
		return

	var gz := StreamPeerGZIP.new()
	err = gz.start_decompression(false, 1000000)
	if err != OK:
		Log.error("Failed to start GZIP decompression with error code %d." % err, LOG_SCOPE)
		extract_complete.emit(module, false)
		return

	const BLOCK_SIZE := 4096
	while in_file.get_position() < in_file.get_length():
		var buf := in_file.get_buffer(BLOCK_SIZE)
		gz.put_data(buf)
		var gz_out: Array = gz.get_partial_data(gz.get_available_bytes())
		out_file.store_buffer(gz_out[1])

	Log.info("Finished downloading and extracting module %s." % module, LOG_SCOPE)

	out_file.close()
	DirAccess.remove_absolute(gz_path)
	extract_complete.emit(module, true)


## Get the download progress of the given [param module]. Returns a two-element
## array containing the downloaded size and the full size or [code]-1[/code] if
## the size is not available. Returns [code][-1, -1][/code] if the file is not
## found.
func get_download_progress(module: String) -> PackedInt32Array:
	var path := _downloads.get(module, "")
	if path.is_empty():
		return [-1, -1]

	return _pool.get_download_progress(path)
