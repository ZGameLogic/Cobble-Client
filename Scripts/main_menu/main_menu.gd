extends Node

var username_label: RichTextLabel

func login():
	WebSocketManager.open_login_browser()
	print("loging in")
	
func continue_start_game():
	print("game")

func _ready():
	username_label = $TopRight/VBoxContainer/UserNameLabel
	WebSocketController.connect("username", self.user_name_change)
	
func user_name_change(name: String):
	print(name)
	username_label.clear()
	username_label.append_text(name)
