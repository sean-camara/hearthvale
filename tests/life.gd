extends SceneTree

const Life=preload("res://scripts/world_life.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
const Travelers=preload("res://scripts/traveling_residents.gd")
var game
var world
var checks:=0
var errors:=0

func _initialize():
	call_deferred("run")

func check(ok:bool,message:String):
	checks+=1
	if not ok:
		errors+=1
		printerr("FAIL: "+message)

func press(label:String):
	for node:Node in game.modal_box.get_children():
		if node is Button and node.text.begins_with(label):
			node.pressed.emit()
			return
	check(false,"Missing button: "+label)

func click_button(text:String):
	await process_frame
	for node:Node in game.modal_box.get_children():
		if not node is Button or not node.text.begins_with(text):continue
		var at:Vector2=node.get_global_rect().get_center()
		var move:=InputEventMouseMotion.new()
		move.position=at
		root.push_input(move,true)
		for down in [true,false]:
			var event:=InputEventMouseButton.new()
			event.position=at
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=down
			root.push_input(event,true)
		await process_frame
		return
	check(false,"No clickable button: "+text)

func screenshot(name_:String):
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://docs/life/"+name_+".png")
	check(root.get_texture().get_image().save_png(path)==OK,"render "+name_)

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	world=game.world
	game.start(889000+randi()%4000)
	game.finish_character()
	game.close_page()
	var model=game.model
	model.s.time=600
	check(model.s.coins==24,"normal starting balance")
	world.enter("Mercantile",Vector2(577,480))
	game.interact("Mercantile counter")
	press("Pickaxe")
	check(model.s.tools.get("pickaxe",false) and model.s.coins==4,"starter can buy a pickaxe")
	press("Axe")
	check(not model.s.tools.get("axe",false) and model.s.coins==4,"unaffordable purchase keeps coins and inventory")
	check(game.purchase_status.text.contains("14 more crowns"),"shortfall appears above the tool list")
	game.close_page()
	model.s.coins=24
	world.enter("Shop:Tool & Hardware",Vector2(573,386))
	game.interact("counter:Tool & Hardware")
	press("Axe")
	check(game.page=="Purchase","axe detail at Arcade")
	await screenshot("starter-axe")
	await click_button("Buy for")
	check(model.s.tools.get("axe",false) and model.s.coins==6,"starter can buy an axe in a department")
	game.close_page()
	world.enter("Grove",Vector2(197,498))
	for i in range(3):
		world.tick(.4)
		game.interact("resource:alder-west")
	check(model.qty("wood")==4,"axe equips and actually chops")
	game.store()
	check(model.load_game() and model.s.tools.axe and model.s.tools.pickaxe,"both purchased tools persist")

	world.enter("Farm",Vector2(905,433))
	game.interact("Fish the creek")
	check(world.fishing.phase=="cast" and game.fishing_button.disabled,"casting locks reel button")
	game.reel()
	check(game.page=="Creek fishing" and model.s.catches.is_empty(),"early reel keeps the cast live")
	game._process(.58)
	check(world.fishing.phase=="wait" and world.tool_sprite.visible,"waiting visible beside the creek")
	game.fishing_time=game.bite_at+(asin((.61-.5)/.45)+.8)/(float(game.fishing_spec.speed)*2.2)
	game._process(0)
	check(game.fishing_status.text=="Reel now!" and not game.fishing_button.disabled and world.fishing.phase=="bite","clear successful input cue")
	await screenshot("bite")
	var key:=InputEventKey.new()
	key.keycode=KEY_SPACE
	key.physical_keycode=KEY_SPACE
	key.pressed=true
	game._unhandled_input(key)
	check(world.fishing.phase=="catch" and model.qty(game.fishing_spec.id)==1,"Space lands fish once")
	world.tick(.54)
	await screenshot("fish-landed")
	world.tick(.5)
	check(world.fishing.phase=="" and not world.tool_sprite.visible and is_zero_approx(world.runner.rotation),"recovery restores movement and sprite")
	game.interact("Fish the creek")
	game.fishing_time=game.bite_at
	game.reel()
	check(world.fishing.phase=="miss" and model.s.catches.size()==1,"miss animation leaves catch record unchanged")
	game.interact("Fish the creek")
	game.close_page()
	check(world.fishing.phase=="" and not world.tool_sprite.visible,"cancel clears tackle")

	for resident:String in Travelers.PEOPLE:
		var row:Array=Travelers.PEOPLE[resident].route[0]
		world.enter(row[1],Vector2(row[2],row[3])+Vector2(0,38))
		model.s.day=0
		model.s.time=370
		world.tick(0)
		check(world.npcs[resident].visible and not world.blocked(world.targets[resident]),resident+" has a walkable scheduled position")
		game.interact(resident)
		check(game.page=="Conversation",resident+" opens dialogue")
		if resident=="Soren":
			game.dialogue_tween.custom_step(1)
			await screenshot("soren-dialogue")
		game.dialogue_topic("request")
		check(model.s.requests.get(resident)=="active",resident+" has a personal request")
		var request:=Life.request_for(resident)
		model.change(request.item,int(request.qty))
		game.dialogue_topic("request")
		check(model.s.requests.get(resident)=="done",resident+" request rewards player")
		game.close_page()
	model.s.day=5
	model.s.time=600
	world.enter("Village",Vector2(782,477))
	world.tick(0)
	check(world.npcs.Soren.visible,"weekly visit adds resident to village")
	var file:String=model.path_for()
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(file+suffix)
	game.music.stop()
	game.fx.stop()
	game.ambiance.stop()
	await create_timer(.24).timeout
	game.queue_free()
	await process_frame
	print("%d village life checks, %d failures"%[checks,errors])
	quit(1 if errors else 0)
