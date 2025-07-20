extends Node

signal websocket_message_received(msg: Dictionary)
signal oauth_code_received(code: String)

var peer: WebSocketPeer = WebSocketPeer.new()
var token_file_path = "user://data.dat"
var server := TCPServer.new()
var client := StreamPeerTCP.new()
var listening := false
var connected := false

func _ready():
	var token = load_token()
	if token == "":
		open_login_browser()
		start_local_http_listener()
	else:
		print("Token loaded: ", token)
		open_web_socket_connection("", token)

func save_token(token: String):
	var file = FileAccess.open(token_file_path, FileAccess.WRITE)
	if file:
		file.store_string(token)
		file.close()
	else:
		print("Failed to open file for writing")

func load_token() -> String:
	if not FileAccess.file_exists(token_file_path):
		return ""
	var file = FileAccess.open(token_file_path, FileAccess.READ)
	if file:
		var token = file.get_as_text()
		file.close()
		return token
	else:
		print("Failed to open file for reading")
		return ""

func open_web_socket_connection(code: String, token: String):
	var url = "wss://cobble-dev.zgamelogic.com/ws"
	var headers = peer.handshake_headers;
	if code != "":
		print("Connecting with code: " + code)
		headers.append("code: " + code)
	elif token != "":
		print("Connecting with token: " + token)
		headers.append("token: " + token)
	else:
		print("No code or token provided.")
		return
	peer.handshake_headers = headers
	var err := peer.connect_to_url(url)
	if err != OK:
		print("WebSocket connection failed with error: ", err)
	else:
		print("WebSocket connection initiated.")

	
func open_login_browser():
	var url = "https://discord.com/oauth2/authorize?client_id=1387512396301598792&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A8090%2Fregister&scope=identify"
	OS.shell_open(url)

func start_local_http_listener():
	server.listen(8090)
	listening = true
	print("Listening on http://localhost:8090")
	
func send_message(msg: String):
	peer.send_text(msg)

func _process(delta):
		# Handle WebSocket polling
	peer.poll()
	match peer.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			print("⚠️ Connecting...")
		WebSocketPeer.STATE_OPEN:
			# Connected, check for incoming data 
			while peer.get_available_packet_count() > 0:
				var json = JSON.new()
				var result = json.parse(peer.get_packet().get_string_from_utf8())
				var data = json.data
				emit_signal("websocket_message_received", data)
		WebSocketPeer.STATE_CLOSING:
			print("⚠️ Closing connection...")
		WebSocketPeer.STATE_CLOSED:
			print("❌ Connection closed")

	if listening and server.is_connection_available():
		client = server.take_connection()
		client.set_no_delay(true)
		var request = client.get_utf8_string(client.get_available_bytes())
		print("Request received:\n", request)

		# Basic parse of GET request
		if request.begins_with("GET /register?code="):
			var start = request.find("?code=") + 6
			var end = request.find(" ", start)
			var code = request.substr(start, end - start)
			print("OAuth2 code received: ", code)
			open_web_socket_connection(code, "")

			# Respond with a simple success page
			var response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html><body>Login successful! You can close this window.</body></html>"
			client.put_utf8_string(response)
			client.put_utf8_string("\r\n") # Just in case
			client.put_data([])
			
			await get_tree().create_timer(0.2).timeout
			
			client.disconnect_from_host()
			listening = false
			server.stop()
