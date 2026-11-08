extends Node

signal connection_changed(connected: bool, message: String)
signal match_joined(match_id: String)
signal match_state_received(state: Dictionary)
signal peer_left(user_id: String)

const INPUT_OPCODE := 1
const STATE_OPCODE := 2

var server_host := "127.0.0.1"
var server_port := 7350
var server_key := "defaultkey"
var use_tls := false
var session_token := ""
var user_id := ""
var username := ""
var current_match_id := ""
var _socket := WebSocketPeer.new()
var _socket_ready := false
var _request_id := 1
var _pending_join := false

func configure(host: String, port: int = 7350, api_key: String = "defaultkey", tls: bool = false) -> void:
	server_host = host.strip_edges()
	server_port = clampi(port, 1, 65535)
	server_key = api_key
	use_tls = tls

func is_connected_to_server() -> bool:
	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func authenticate_and_connect(display_name: String) -> bool:
	if server_host.is_empty():
		connection_changed.emit(false, "Co-op server address is not configured.")
		return false
	username = display_name.strip_edges()
	if username.is_empty():
		username = "Survivor"
	var device_id := _get_device_id()
	var scheme := "https" if use_tls else "http"
	var url := "%s://%s:%d/v2/account/authenticate/device?create=true&username=%s" % [
		scheme, server_host, server_port, username.uri_encode()
	]
	var auth := await _http_json(url, HTTPClient.METHOD_POST, {"id": device_id}, [
		"Authorization: Basic " + Marshalls.utf8_to_base64(server_key + ":")
	])
	if not auth.has("token"):
		connection_changed.emit(false, str(auth.get("error", "Authentication failed.")))
		return false
	session_token = str(auth.token)
	user_id = str(auth.get("user_id", ""))
	var socket_scheme := "wss" if use_tls else "ws"
	var socket_url := "%s://%s:%d/ws?lang=en&status=false&token=%s" % [
		socket_scheme, server_host, server_port, session_token.uri_encode()
	]
	var err := _socket.connect_to_url(socket_url)
	if err != OK:
		connection_changed.emit(false, "Could not start the co-op socket connection.")
		return false
	var deadline := Time.get_ticks_msec() + 10000
	while _socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING and Time.get_ticks_msec() < deadline:
		_socket.poll()
		await get_tree().create_timer(0.1).timeout
	if not is_connected_to_server():
		connection_changed.emit(false, "Co-op server connection timed out.")
		return false
	_socket_ready = true
	connection_changed.emit(true, "Connected to co-op server.")
	return true

func create_match() -> bool:
	if not is_connected_to_server():
		connection_changed.emit(false, "Connect to the co-op server first.")
		return false
	var scheme := "https" if use_tls else "http"
	var url := "%s://%s:%d/v2/rpc/create_coop_match?http_key=%s&unwrap=true" % [
		scheme, server_host, server_port, server_key.uri_encode()
	]
	var result := await _http_json(url, HTTPClient.METHOD_POST, {}, [
		"Authorization: Bearer " + session_token
	])
	var new_match_id := str(result.get("match_id", ""))
	if new_match_id.is_empty():
		connection_changed.emit(false, str(result.get("error", "Unable to create a co-op session.")))
		return false
	return await join_match(new_match_id)

func join_match(match_id: String) -> bool:
	if not is_connected_to_server() or match_id.strip_edges().is_empty():
		return false
	current_match_id = match_id.strip_edges()
	var message := {
		"cid": str(_request_id),
		"match_join": {"match_id": current_match_id}
	}
	_request_id += 1
	_pending_join = true
	var err := _socket.send_text(JSON.stringify(message))
	if err != OK:
		_pending_join = false
		connection_changed.emit(false, "Could not send the join request.")
		return false
	return true

func send_player_input(move: Vector2, yaw: float) -> void:
	if not is_connected_to_server() or current_match_id.is_empty():
		return
	var payload := JSON.stringify({
		"move_x": clampf(move.x, -1.0, 1.0),
		"move_z": clampf(move.y, -1.0, 1.0),
		"yaw": yaw
	})
	var message := {
		"cid": str(_request_id),
		"match_data_send": {
			"match_id": current_match_id,
			"op_code": INPUT_OPCODE,
			"data": Marshalls.utf8_to_base64(payload)
		}
	}
	_request_id += 1
	_socket.send_text(JSON.stringify(message))

func leave_match() -> void:
	if is_connected_to_server() and not current_match_id.is_empty():
		_socket.send_text(JSON.stringify({
			"cid": str(_request_id),
			"match_leave": {"match_id": current_match_id}
		}))
		_request_id += 1
	current_match_id = ""
	_pending_join = false

func disconnect_from_server() -> void:
	leave_match()
	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.close()
	session_token = ""
	_socket_ready = false
	connection_changed.emit(false, "Disconnected from co-op server.")

func _process(_delta: float) -> void:
	if _socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		return
	_socket.poll()
	while _socket.get_ready_state() == WebSocketPeer.STATE_OPEN and _socket.get_available_packet_count() > 0:
		var packet := _socket.get_packet().get_string_from_utf8()
		var parsed = JSON.parse_string(packet)
		if parsed is Dictionary:
			_handle_socket_message(parsed)

func _handle_socket_message(message: Dictionary) -> void:
	if message.has("match") and _pending_join:
		_pending_join = false
		var match_data: Dictionary = message.match
		current_match_id = str(match_data.get("match_id", current_match_id))
		match_joined.emit(current_match_id)
		connection_changed.emit(true, "Joined co-op session.")
	elif message.has("match_data"):
		var data: Dictionary = message.match_data
		if int(data.get("op_code", 0)) == STATE_OPCODE:
			var decoded := Marshalls.base64_to_utf8(str(data.get("data", "")))
			var state = JSON.parse_string(decoded)
			if state is Dictionary:
				match_state_received.emit(state)
	elif message.has("match_presence_event"):
		var event: Dictionary = message.match_presence_event
		for presence in event.get("joins", []):
			pass
		for presence in event.get("leaves", []):
			peer_left.emit(str(presence.get("user_id", "")))
	elif message.has("error"):
		_pending_join = false
		connection_changed.emit(false, str(message.error.get("message", "Co-op server error.")))

func _http_json(url: String, method: int, payload: Dictionary, headers: PackedStringArray) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 15.0
	add_child(request)
	var all_headers := headers.duplicate()
	all_headers.append("Content-Type: application/json")
	var err := request.request(url, all_headers, method, JSON.stringify(payload))
	if err != OK:
		request.queue_free()
		return {"error": "Could not start server request (%s)." % error_string(err)}
	var response = await request.request_completed
	request.queue_free()
	var result_code: int = response[0]
	var status_code: int = response[1]
	var body: PackedByteArray = response[3]
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {"error": "Network request failed (%d)." % result_code}
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if status_code < 200 or status_code >= 300:
		if parsed is Dictionary:
			return {"error": str(parsed.get("message", parsed.get("error", "Server returned HTTP %d." % status_code)))}
		return {"error": "Server returned HTTP %d." % status_code}
	return parsed if parsed is Dictionary else {}

func _get_device_id() -> String:
	var path := "user://coop_device_id"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var saved := file.get_as_text().strip_edges()
			file.close()
			if not saved.is_empty():
				return saved
	var id := Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(id)
		file.close()
	return id
