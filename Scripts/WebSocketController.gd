extends Node

var username: String
var avatar: String
var userId: int
var game_check = false

func _ready():
	WebSocketManager.connect("websocket_message_received", self.on_websocket_message_recieve)
	
func on_websocket_message_recieve(msg: Dictionary):
	if msg.statusCode != 200:
		print(msg)
		return

	match msg["type"]:
		"AUTHENTICATE":
			username = msg.data.username
			avatar = msg.data.avatar
			userId = msg.data.userId
			print("Welcome " + username + " " + str(userId))
			var token = msg["data"]["rollingToken"]
			WebSocketManager.save_token(token)
			WebSocketManager.send_message("{\"type\": \"game-check\"}")
		"initial":
			print(msg)
		"game-check":
			game_check = msg.data
