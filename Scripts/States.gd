extends Node

signal logged_in_signal(logged_in: bool)
signal connected_signal(connected: bool)

var logged_in := false
var connected := false

func set_logged_in(logged_in: bool):
	self.logged_in = logged_in
	emit_signal(logged_in_signal.get_name(), logged_in)
	
func set_connected(connected: bool):
	self.connected = connected
	emit_signal(connected_signal.get_name(), connected)
