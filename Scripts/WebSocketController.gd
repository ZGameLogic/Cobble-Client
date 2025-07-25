extends Node

signal username(code: String)

var user_name: String
var avatar: String
var userId: int
var game_check := false

func _ready():
	WebSocketManager.connect("websocket_message_received", self.on_websocket_message_receive)
	
func on_websocket_message_receive(msg: Dictionary) -> void:
	if msg.statusCode != 200:
		print(msg)
		return

	match msg["type"]:
		"AUTHENTICATE":
			user_name = msg.data.username
			avatar = msg.data.avatar
			userId = msg.data.userId
			print("Welcome " + user_name + " " + str(userId))
			var token = msg["data"]["rollingToken"]
			WebSocketManager.save_token(token)
			WebSocketManager.send_message("{\"type\": \"game-check\"}")
			emit_signal(username.get_name(), user_name)
		"initial":
			print(msg)
		"game-check":
			game_check = msg.data
