extends Control

@export var address = "127.0.0.1"
@export var port = 1118

var peer
var scene_name: String = "res://scenes/TestScene.tscn"
var compression = ENetConnection.COMPRESS_RANGE_CODER

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)



func _process(_delta):
	pass


#called on the server and clients
func player_connected(id):
	print("Player connected " + str(id))

#called on the server and clients
func player_disconnected(id):
	print("Player disconnected " + str(id))
	
#called only on clients
func connected_to_server():
	print("connected to server")
	send_player_information.rpc_id(1, $Name.text, multiplayer.get_unique_id())
	
#called only on clients
func connection_failed():
	print("connection failed")

@rpc("any_peer")
func send_player_information(name, id):
	if !GameManager.players.has(id):
		GameManager.players[id] ={
			"name":name,
			"id":id
		}
	
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_information.rpc(GameManager.players[i].name, i)



@rpc("any_peer","call_local")
func start_game():
	var scene = load(scene_name).instantiate()
	get_tree().root.add_child(scene)
	self.hide()


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("can't host " + str(error))
		return
	peer.get_host().compress(compression)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players...")
	send_player_information($Name.text, multiplayer.get_unique_id())



func _on_join_button_down():
	if !($Address.text == ""):
		address = $Address.text
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(compression)
	multiplayer.set_multiplayer_peer(peer)




func _on_start_game_button_down():
	start_game.rpc()


func _on_load_scene_1_button_down():
	scene_name = "res://scenes/TestScene.tscn"
	
func _on_load_scene_2_button_down():
	scene_name = "res://scenes/navigation_test.tscn"



