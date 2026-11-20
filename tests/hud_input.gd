extends SceneTree

var failed:=0
func check(result:bool,msg:String):
	if not result:failed+=1;printerr("FAIL: "+msg)
func click(at:Vector2):
	var move:=InputEventMouseMotion.new()
	move.position=at;move.global_position=at
	root.push_input(move,true)
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=at;event.global_position=at
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		root.push_input(event,true)
	await process_frame
func key(code:Key):
	for down in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=code;event.physical_keycode=code;event.pressed=down
		root.push_input(event,true)
	await process_frame
func _initialize():call_deferred("run")
func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(510000+randi()%30000)
	game.finish_character();game.close_page()
	await process_frame
	var water:Button=game.farm_hud.slots[2]
	await click(water.get_global_rect().get_center())
	check(game.world.tool==2,"clicking watering can selects tool")
	await key(KEY_4)
	check(game.world.tool==3,"harvest hotkey")
	game.world.pos=Vector2(429,382)
	game.world.tick(0)
	await key(KEY_E)
	check(game.page=="Storage chest","interaction key opens storage")
	var first:Button=game.modal_box.get_child(1)
	var before:int=game.model.qty("s0")
	await click(first.get_global_rect().get_center())
	check(game.model.qty("s0")==before-1 and game.model.s.chest.get("s0",0)==1,"painted storage row transfers one item")
	await key(KEY_ESCAPE)
	await click(Vector2(1196,40))
	check(game.page=="Journal","wooden journal button")
	await key(KEY_ESCAPE)
	game.model.change("p0",1);game.update_hud()
	await key(KEY_5)
	check(game.page=="Satchel","produce quick slot opens satchel")
	game.close_page();game.world.pos=Vector2(679,339);game.world.tick(0)
	await key(KEY_E)
	check(game.page=="Seed market","seed counter proximity interaction")
	var purchase:Button=game.modal_box.get_child(2)
	var coins:int=game.model.s.coins
	await click(purchase.get_global_rect().get_center())
	check(game.model.s.coins<coins,"market purchase from painted row")
	game.music.stop();game.fx.stop()
	await create_timer(.65).timeout
	for suffix in ["",".bak"]:DirAccess.remove_absolute(game.model.path_for()+suffix)
	print("HUD and input regression failures: ",failed)
	quit(1 if failed else 0)

