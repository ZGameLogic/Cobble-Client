extends Node

var peer: WebSocketPeer = WebSocketPeer.new()

func _ready():
	print("🌐 Connecting to WebSocket...")

	var url := get_websocket_url()
	var err := peer.connect_to_url(url)

	if err != OK:
		print("❌ Failed to connect to WebSocket server at %s" % url)
	else:
		print("🔌 Connecting to: %s" % url)

	# Poll every frame to process connection and data
	get_tree().connect("process_frame", Callable(self, "_on_process_frame"))

func _on_process_frame():
	peer.poll()

	match peer.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass  # still connecting
		WebSocketPeer.STATE_OPEN:
			# Connected, check for incoming data
			while peer.get_available_packet_count() > 0:
				var msg = peer.get_packet().get_string_from_utf8()
				print("📨 Received: %s" % msg)
		WebSocketPeer.STATE_CLOSING:
			print("⚠️ Closing connection...")
		WebSocketPeer.STATE_CLOSED:
			print("❌ Connection closed")

func get_websocket_url() -> String:
	return "wss://cobble-dev.zgamelogic.com/ws"
	#if Engine.is_editor_hint():
		#return "ws://localhost:8080/ws" # dev server
	#else:
		#return "wss://cobble.zgamelogic.com/ws" # production server
