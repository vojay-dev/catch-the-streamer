extends Node2D

const TWITCH_CHANNEL = "vojay"

var enemy = preload("res://Enemy.tscn")
onready var spawn_positions = [$Spawn1, $Spawn2, $Spawn3]

func _ready():
	randomize()
	$TwitchClient.channel_name = TWITCH_CHANNEL
	$TwitchClient.irc_connect()
	$TwitchClient.start()
	$Chat.bbcode_text = "[color=#63ff8d]Channel:[/color] %s\n" % TWITCH_CHANNEL

func _on_TwitchClient_received_chat_message(user, message):
	$Chat.bbcode_text = $Chat.bbcode_text + "[color=#ff0]%s:[/color] %s\n" % [
		user,
		$TwitchClient.clear_message(message, -1)
	]

	var enemy_instance = enemy.instance()

	enemy_instance.position = spawn_positions[randi() % spawn_positions.size()].position
	enemy_instance.set_name(user)

	$Enemies.add_child(enemy_instance)
