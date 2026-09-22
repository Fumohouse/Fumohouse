class_name HTTPRequestPool
extends Node
## A pool of [HTTPRequest], to be used for concurrent HTTP requests.

var _active: Dictionary[Node, bool] = {}
var _download_to_request: Dictionary[String, HTTPRequest] = {}


## Perform an HTTP request. Asynchronous function returns the response data as
## a dictionary.
func request(
	url: String,
	headers: PackedStringArray,
	method: HTTPClient.Method,
	request_data: PackedByteArray,
	download_path := ""
) -> Response:
	var req := _get_http_request()
	_active[req] = true
	req.download_file = download_path
	if not download_path.is_empty():
		_download_to_request[download_path] = req

	var out := Response.new()

	out.err = req.request_raw(url, headers, method, request_data)
	if out.err != OK:
		return out

	var res: Array = await req.request_completed
	_active[req] = false
	if not download_path.is_empty():
		_download_to_request.erase(download_path)

	out.result = res[0]
	out.status = res[1]
	out.headers = res[2]
	out.body = res[3]
	return out


## Perform an HTTP request using [param callback]. The callback should accept
## a [HTTPResponse].
func request_cb(
	url: String,
	headers: PackedStringArray,
	method: HTTPClient.Method,
	request_data: PackedByteArray,
	callback: Callable,
	download_path := ""
):
	var res := await request(url, headers, method, request_data, download_path)
	callback.call(res)


## Get the download progress of the given [param file]. Returns a two-element
## array containing the downloaded size and the full size or [code]-1[/code] if
## the size is not available. Returns [code][-1, -1][/code] if the file is not
## found.
func get_download_progress(file: String) -> PackedInt32Array:
	var req: HTTPRequest = _download_to_request.get(file)
	if not req:
		return [-1, -1]

	return [req.get_downloaded_bytes(), req.get_body_size()]


func _get_http_request() -> HTTPRequest:
	for child: HTTPRequest in get_children():
		if not _active.get(child, false):
			return child

	var req := HTTPRequest.new()
	req.use_threads = true
	add_child(req)
	return req


class Response:
	extends RefCounted
	var err: Error
	var result: HTTPRequest.Result
	var status: HTTPClient.Status
	var headers: PackedStringArray
	var body: PackedByteArray
