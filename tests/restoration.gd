extends SceneTree

const Projects=preload("res://scripts/village_projects.gd")
var game
var model
var world
var checks:=0
var failures:=0

func _initialize():call_deferred("run")

func check(ok:bool,message:String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+message)

func visit(area:String,point:Vector2):
	game.close_page()
	world.enter(area,point)

func use(id:String):
	check(world.targets.has(id),"target "+id)
	if not world.targets.has(id):return
	var at:Vector2=world.targets[id]
	var reachable:=false
	for offset in [Vector2(0,22),Vector2(16,12),Vector2(-16,12),Vector2(0,-16)]:
		if world.blocked(at+offset):continue
		world.pos=at+offset
		reachable=true
		break
	check(reachable,"reach "+id)
	game.interact(id)

func select_button(prefix:String):
	for child in game.modal_box.get_children():
		if child is Button and child.text.trim_prefix("✓ ").begins_with(prefix):
			child.pressed.emit()
			return
	check(false,"missing button "+prefix)

func capture(label:String):
	if DisplayServer.get_name()=="headless":return
	game.update_hud()
	game.toast.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP")+"/hearth-roots-"+label+".png")

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.start(991000+randi()%8000)
	game.finish_character()
	game.begin_first_morning()
	model=game.model
	world=game.world
	var progress:Dictionary=Projects.data(model)
	game.show_page("Journal")
	select_button("Market supper")
	check(game.page==Projects.Market,"market discoverable on day one")
	game.close_page()
	for path in [["grow","Grow","p0",2,"Deliver two"],["fish","Catch","perch",1,"Deliver Copper perch"],["build","Bring","wood",4,"Deliver four"]]:
		for key in ["market-choice","market-delivery","market-keepsake"]:progress.erase(key)
		model.s.day=0
		model.s.time=700
		visit("Village",Vector2(796,465))
		model.change(path[2],path[3])
		model.s.catches.perch=1
		use(Projects.Market)
		select_button(path[1])
		select_button(path[4])
		check(progress.get("market-delivery","")==path[0],"contribution handed in")
		model.s.day=13
		model.s.time=600
		use(Projects.Market)
		var before:int=model.s.coins
		select_button("Join the market supper")
		check(progress.get("market-keepsake","")==path[0] and model.s.coins==before+45,"next week outcome and reward")
		Projects.finish_market(game,path[0])
		check(model.s.coins==before+45,"no double market reward")
	await capture("market")
	visit("Farm",Vector2(385,672))
	use(Projects.Orchard)
	select_button("Clear fallen branches")
	check(not progress.has("orchard-cleared"),"orchard requires axe")
	model.s.tools.axe=true
	select_button("Clear fallen branches")
	select_button("Graft")
	check(progress.get("orchard-plan","")=="pear","orchard graft")
	Projects.harvest_orchard(game)
	check(model.qty("orchard-pear")==0,"orchard needs time")
	model.s.day+=7
	visit("Farm",Vector2(443,687))
	use(Projects.Orchard)
	select_button("Gather three")
	select_button("Make pear preserves")
	check(model.qty("orchard-jar")==1 and model.qty("orchard-pear")==1,"fruit preserves")
	world.pos=Vector2(445,681)
	world.tick(0)
	game.close_page()
	await capture("orchard")
	model.change("stone",3)
	model.change("wood",8)
	use(Projects.Bridge)
	select_button("Restore the footbridge")
	world.tick(0)
	await capture("bridge")
	use(Projects.Bridge)
	check(world.area=="Grove","outward bridge")
	use(Projects.Bridge)
	check(world.area=="Farm","return bridge")
	visit("Bakery",Vector2(520,389))
	var before:int=model.s.coins
	use(Projects.Work)
	select_button("A jar")
	check(model.s.coins==before+56,"cottage preserves commission")
	model.s.requests.Linn="done"
	game.show_page(Projects.Walk)
	select_button("Accept")
	model.s.time=490
	visit("Forest",Vector2(662,537))
	use(Projects.Walk)
	select_button("Take the trail")
	use(Projects.Walk)
	select_button("Plant on the sheltered")
	model.s.day+=21
	visit("Forest",Vector2(685,571))
	use(Projects.Walk)
	select_button("Gather herbs")
	check(model.qty("frogmint")==3,"Linn’s herb patch grows")
	model.s.mine.depth=3
	model.s.mine.day=model.s.day
	visit("Mine",Vector2(380,475))
	use("Slate quarry spur")
	check(world.area=="Mine","locked quarry")
	model.s.mine.cleared["3"]=1
	use("Slate quarry spur")
	check(world.area=="SlateSpur","quarry spur entry")
	use("Slate seam 389")
	check(model.craft("slate-path"),"slate used in workshop")
	use("Return to mine")
	check(world.area=="Mine","quarry return")
	model.s.mine.depth=7
	model.s.mine.cleared["7"]=1
	visit("Mine",Vector2(790,425))
	use("Flooded side chamber")
	check(world.area=="FloodedSpur","flooded side chamber entry")
	use("Lantern pool")
	check(game.page=="Creek fishing" and game.fishing_spec.id=="cave-char","side chamber fishing")
	game.close_page()
	await capture("chamber")
	for index in 8:
		var find:Array=Projects.FieldNotes[index]
		model.s.day=index*21+1
		visit(find[0],find[2]+Vector2(0,19))
		use(find[1])
		check(progress.has("discovery-"+str(index)),"seasonal discovery "+str(index))
		if index==3:check(world.area=="Forest","Raincall crossing")
		if index==6:check(world.area=="Highlands","Snowrest crossing")
	game.store()
	check(model.load_game() and Projects.data(model).has("orchard-plan") and Projects.data(model).has("south-bridge"),"restoration persists")
	var file:String=model.path_for()
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(file+suffix)
	game.music.stop()
	game.fx.stop()
	game.ambiance.stop()
	await create_timer(.25).timeout
	game.queue_free()
	await process_frame
	print("%d restoration checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

