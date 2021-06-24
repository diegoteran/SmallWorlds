extends Area2D

var players = {}
var player = null

func can_see_player():
	return players.size() > 0

func _on_PlayerDetectionZone_body_entered(body):
	players[body.name] = body
	choose_new_player()

func _on_PlayerDetectionZone_body_exited(body):
	players.erase(body.name)
	if players.size() > 0:
		choose_new_player()
	else:
		player = null

func choose_new_player():
	var player_key = players.keys()[randi() % players.size()]
	player = players[player_key]
