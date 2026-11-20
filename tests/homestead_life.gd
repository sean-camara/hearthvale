extends SceneTree

const Life=preload("res://scripts/homestead_life.gd")
const Trails=preload("res://scripts/valley_trails.gd")
var game
var w
var m
var checks:=0
var failures:=0

func _initialize():call_deferred("run")

func check(ok:bool,label:String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+label)

func visit(area:String,at:Vector2):
	game.close_page()
	w.enter(area,at)

func use(id:String):
	game.close_page()
	check(w.targets.has(id),"target "+id)
	if not w.targets.has(id):return
	var at:Vector2=w.targets[id]
	var reached:=false
	for offset in [Vector2(0,24),Vector2(21,12),Vector2(-21,12),Vector2(0,-20)]:
		var candidate:Vector2=at+offset
		if w.blocked(candidate):continue
		w.pos=candidate
		reached=true
		break
	check(reached,"reachable "+id)
	game.interact(id)

func button(prefix:String):
	if is_instance_valid(game.modal_box):
		for child in game.modal_box.get_children():
			if child is Button and child.text.begins_with(prefix) and not child.disabled:
				child.pressed.emit()
				return
	check(false,"missing action "+prefix)

func capture(label:String,at:Vector2):
	if DisplayServer.get_name()=="headless":return
	game.close_page()
	w.pos=at
	w.tick(0)
	game.toast.hide()
	game.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP")+"/hearth-trails-"+label+".png")

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.start(997000+randi()%10000)
	game.finish_character()
	game.begin_first_morning()
	w=game.world
	m=game.model
	m.s.time=520
	m.s.coins=400
	visit("Grove",Vector2(318,545))
	for area:String in Trails.trails:
		for side:String in game.Routes.links(area):
			var lane:Vector2=game.Routes.links(area)[side][2]
			var a:=(lane.x+lane.y)*.5
			var edge:Vector2={"north":Vector2(a,0),"south":Vector2(a,767),"west":Vector2(0,a),"east":Vector2(1151,a)}[side]
			if area=="Village" and side in ["north","west"]:continue
			check(Trails.distance_to_trail(area,edge)<=5,area+" "+side+" trail at real exit")
	await capture("grove",Vector2(316,545))
	for route:Array in [["Grove","west","Forest",Vector2(14,610)],["Forest","west","Marsh",Vector2(14,610)]]:
		var path:PackedVector2Array=w.schedules.path(w.pos,route[3])
		check(path.size()>1 and path[-1].distance_to(Vector2(route[3]))<23,"walk to "+route[2])
		game.cross_region(route[0],route[1],route[3])
		check(w.area==route[2],"cross to "+route[2])
		if w.area=="Forest":
			await capture("forest",Vector2(631,565))
			use(Life.ForestLodge)
			button("Creek mint")
			check(m.qty("herb")==1,"buy from field lodge")
	await capture("marsh",Vector2(647,523))
	await capture("marsh-boardwalk",Vector2(930,592))
	check(w.blocked(Vector2(967,469)) and not w.blocked(Vector2(1005,610)),"water and boardwalk align with movement")
	use("Maelin")
	check(game.page=="Conversation","witch in marsh")
	game.dialogue_topic("request")
	check(m.s.requests.Maelin=="active","alchemist side quest")
	use("Moonreed bed 461")
	use("Moonreed bed 461")
	check(m.qty("moonreed")==2,"moonreed replenishes overnight")
	use(Life.Alchemy)
	check(w.area=="AlchemyRoom","separate lab")
	await capture("alchemy",Vector2(576,474))
	use("Alchemy bench")
	button("Bring two moonreed")
	check(Life.progress(m).get("alchemy-trained",false),"learn alchemy")
	use("Maelin’s shop")
	button("Moonreed")
	use("Alchemy bench")
	button("Brew Stillwater")
	game.show_page("Satchel")
	button("Use Stillwater")
	m.change("moonreed",1)
	m.change("woodland-cap",1)
	use("Alchemy bench")
	button("Brew Stoneleaf")
	use("Leave apothecary")
	game.start_fishing("marsh")
	check(game.tonic_cast and not Life.progress(m).has("tonic-cast"),"tonic used by next cast")
	game.close_page()
	game.start_fishing("marsh")
	check(not game.tonic_cast,"no repeat tonic")
	visit("Mine",Vector2(576,480))
	m.s.mine.energy=48
	game.show_page("Satchel")
	button("Use Stoneleaf")
	check(is_equal_approx(float(m.s.mine.energy),78.0),"salve restores mining energy")
	m.change("wood",6)
	visit("Farm",Vector2(822,605))
	use(Life.Pasture)
	button("Open south pasture")
	check(w.area=="Pasture","open pasture")
	use(Life.Stock)
	button("Buy Goat")
	button("Buy Sheep")
	check(w.targets.has("Tend goat") and w.targets.has("Tend sheep"),"both animals present")
	use("Cut pasture hay")
	use("Tend goat")
	button("Feed one hay")
	use("Tend sheep")
	button("Feed one hay")
	check(m.qty("fodder")==1,"one bundle per fed animal")
	game.dawn()
	use("Tend goat")
	button("Collect Goat milk")
	use("Tend sheep")
	button("Collect Soft wool")
	check(m.qty("goat-milk")==1 and m.qty("soft-wool")==1,"fed animals produce")
	game.dawn()
	check(int(Life.progress(m)["animal-goat"].stock)==0,"unfed animal rests")
	await capture("pasture",Vector2(547,509))
	game.store()
	check(m.load_game() and m.s.area=="Pasture" and Life.progress(m).has("animal-sheep"),"new region save reloads")
	use("Back to Hearthvale")
	check(w.area=="Farm","pasture return path")
	var path:String=m.path_for()
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
	game.music.stop()
	game.fx.stop()
	game.ambiance.stop()
	await create_timer(.25).timeout
	game.queue_free()
	await process_frame
	print("%d trail and homestead checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)


