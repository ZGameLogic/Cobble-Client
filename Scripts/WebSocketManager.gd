extends Node

# TODO make better signals
signal websocket_message_received(msg: String)

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
				emit_signal("websocket_message_received", msg)
		WebSocketPeer.STATE_CLOSING:
			print("⚠️ Closing connection...")
		WebSocketPeer.STATE_CLOSED:
			print("❌ Connection closed")

func get_websocket_url() -> String:
	return "wss://cobble-dev.zgamelogic.com/ws"
	
# This is what to do to subscribe to and listen to the signals
#func _ready():
	#WebSocketManager.connect("websocket_message_received", self, "_on_websocket_message_received")
#
#func _on_websocket_message_received(msg: String):
	#print("📩 GUI got WebSocket message: ", msg)
