extends Node

signal websocket_message_received(msg: Dictionary)
signal oauth_code_received(code: String)

var peer: WebSocketPeer = WebSocketPeer.new()
var token_file_path = "user://data.dat"
var server := TCPServer.new()
var client := StreamPeerTCP.new()
var listening := false
var connected := false
var connecting_with_token := false

# local
#var callback_url = "https://discord.com/oauth2/authorize?client_id=1387512311065084065&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fregister&scope=identify&state="
#var web_socket_url = "ws://localhost:8080/ws"
# dev
var callback_url = "https://discord.com/oauth2/authorize?client_id=1387512311065084065&response_type=code&redirect_uri=https%3A%2F%2Fcobble-dev.zgamelogic.com%2Fregister&scope=identify&state="
var web_socket_url = "wss://cobble-dev.zgamelogic.com/ws"
# prod
#var callback_url = "https://discord.com/oauth2/authorize?client_id=1387512194606039132&response_type=code&redirect_uri=https%3A%2F%2Fcobble.zgamelogic.com%2Fregister&scope=identify&state="
#var web_socket_url = "wss://cobble.zgamelogic.com/ws"

func _ready():
	login()

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
	print(file.get_path_absolute())
	if file:
		var token = file.get_as_text()
		file.close()
		return token
	else:
		print("Failed to open file for reading")
		return ""

func delete_token():
	if not FileAccess.file_exists(token_file_path):
		return
	DirAccess.remove_absolute(token_file_path)

func login():
	var token = load_token()
	if token == "":
		open_login_browser()
	else:
		print("Token loaded: ", token)
		open_web_socket_connection("", token)

func open_web_socket_connection(state: String, token: String):
	var headers = peer.handshake_headers;
	if state != "":
		print("Connecting with state: " + state)
		headers.append("state: " + state)
	elif token != "":
		print("Connecting with token: " + token)
		connecting_with_token = true
		headers.append("token: " + token)
	else:
		print("No code or token provided.")
		return
	peer.handshake_headers = headers
	var err := peer.connect_to_url(web_socket_url)
	if err != OK:
		print("WebSocket connection failed with error: ", err)
	else:
		print("WebSocket connection initiated.")

	
func open_login_browser():
	var state = generate_hex_uuid()
	var url = callback_url + state
	OS.shell_open(url)
	open_web_socket_connection(state, "")
	
func send_message(msg: String):
	peer.send_text(msg)

func _process(delta):
	# Handle WebSocket polling
	peer.poll()
	match peer.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			print("⚠️ Connecting...")
		WebSocketPeer.STATE_OPEN:
			connecting_with_token = false
			# Connected, check for incoming data 
			while peer.get_available_packet_count() > 0:
				var json = JSON.new()
				var result = json.parse(peer.get_packet().get_string_from_utf8())
				var data = json.data
				emit_signal("websocket_message_received", data)
		WebSocketPeer.STATE_CLOSING:
			print("⚠️ Closing connection...")
		WebSocketPeer.STATE_CLOSED:
			if(connecting_with_token): # This means we were connecting with token but failed and the user needs to re-login
				print("Failed to auth with current token")
				delete_token()
				login()
			else: # This means we lost connection and need to reconnect
				login()
			

func generate_hex_uuid() -> String:
	var hex_chars = "0123456789abcdef"
	var uuid = ""
	for i in 32:
		uuid += hex_chars[randi() % hex_chars.length()]
	return uuid
