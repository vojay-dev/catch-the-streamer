class_name TwitchClient
extends Node

signal received_chat_message(user, message)

const CHUNK_BUFFER = 8

export(String) var twitch_host = "irc.chat.twitch.tv"
export(int) var twitch_port = 6667
export(int, 3, 30) var connection_timeout_sec = 10

export(String) var bot_username
export(String) var channel_name
export(String) var oauth_token

var stream = StreamPeerTCP.new()
var message_queue = []
var started = false

func irc_connect():
	irc_disconnect()
	stream = StreamPeerTCP.new()
	print("connect")

	stream.connect_to_host(twitch_host, twitch_port)
	var connecting_start = OS.get_unix_time()

	while stream.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		var time_passed_sec = OS.get_unix_time() - connecting_start
		assert(time_passed_sec < connection_timeout_sec, "ERROR: Connection timeout")

	message_queue.append("PASS oauth:%s" % oauth_token)
	message_queue.append("NICK %s" % bot_username)
	message_queue.append("JOIN #%s" % channel_name.to_lower())

func irc_disconnect():
	print("disconnect")
	stream.disconnect_from_host()

func start():
	started = true

func stop():
	started = false

func send_message(message: String) -> void:
	message_queue.append(message)

func clear_message(message: String, max_length: int = 30) -> String:
	message = message.replace("\\", "")
	message = message.replace("[", "")
	message = message.replace("]", "")

	if max_length >= 0:
		message = message.substr(0, max_length)

	return message

func _ready():
	_init()

func _init():
	randomize()
	if not bot_username:
		bot_username = "justinfan%d" % randi()
	if not oauth_token:
		oauth_token = str(randi())

func _process(_delta):
	if not started:
		return

	if not stream.is_connected_to_host() or stream.get_status() == StreamPeerTCP.STATUS_ERROR:
		print("Lost connection, reconnecting...")
		stream.disconnect_from_host()
		irc_connect()

		return

	# ensure connection is established
	assert(stream.get_status() != StreamPeerTCP.STATUS_ERROR, "ERROR: Lost connection")

	# send queued messages
	while not message_queue.empty():
		var message = message_queue.pop_front()
		stream.put_data(message.to_utf8())
		stream.put_data("\r\n".to_utf8())

	# process incoming messages
	var bytes_available = stream.get_available_bytes()

	if not bytes_available > 0:
		return

	_parse_input_data(stream.get_utf8_string(bytes_available))

func _parse_input_data(input):
	for input_line in input.split("\n"):
		if input.begins_with("PING"):
			_handle_ping(input_line)
		elif input.find(" PRIVMSG ") != -1:
			_handle_chat(input_line)

func _handle_ping(_input):
	message_queue.append("PONG :tmi.twitch.tv")

func _handle_chat(input):
	# See: https://tools.ietf.org/html/rfc1459#section-2.3.1
	var components = input.split(" ")

	# Example: :vojay!vojay@vojay.tmi.twitch.tv
	var user_host = components[0].split('!')
	if not user_host.size() == 2:
		return

	var user = user_host[1].split('@')[0]

	# Reconstruct message
	var message = ""
	for i in range(3, components.size()):
		message += "%s " % components[i]

	# Remove last space (" ") at the end
	message.erase(0, 1)

	# Remove colon (:) at the beginning
	message.erase(message.length() - 1, 1)

	emit_signal("received_chat_message", user, message)
