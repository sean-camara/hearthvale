extends SceneTree

const Market=preload("res://scripts/season_events.gd")
const Mine=preload("res://scripts/mine_progress.gd")
var game
var world
var fails:=0

func _initialize():
	call_deferred("run")

func check(ok:bool,label:String):
	if not ok:
		fails+=1
		printerr("FAIL: "+label)

func show(name_:String):
	if DisplayServer.get_name()=="headless":return
	game.update_hud()
	await create_timer(.47).timeout
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://docs/mine/"+name_+".png")
	check(root.get_texture().get_image().save_png(output)==OK,"captured "+name_)

func hit(id:String):
	world.tick(.35)
	game.interact(id)

func catch_center():
	game.fishing_time=game.bite_at+(asin((.61-.5)/.45)+.8)/(float(game.fishing_spec.speed)*2.2)
	game.reel()

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	world=game.world
	game.start(895000+randi()%4000)
	game.finish_character()
	game.close_page()
	game.interact("Oren")
	game.dialogue_topic("dock")
	check(game.model.s.mine.dock_stage==1,"start dock through Oren")
	game.close_page()
	for day in range(7):
		if game.model.weather(day)=="Showers":
			game.model.s.day=day
			break
	world.enter("Farm",Vector2(923,391))
	game.interact("Fish the creek")
	catch_center()
	check(game.model.s.mine.rain_catch,"qualifying rainy catch")
	game.interact("Oren")
	game.dialogue_topic("dock")
	check(game.model.s.mine.dock_stage==2,"unlock lift objective")
	game.close_page()

	world.enter("Grove",Vector2(960,488))
	game.interact("Alderwood Mine")
	check(world.area=="Grove","pickaxe required")
	game.model.s.tools.pickaxe=true
	game.model.s.coins=200
	game.interact("Mining kit")
	game.buy_supply("mine-lantern",20,"Mining kit")
	game.close_page()
	await show("alderwood-entrance")
	game.interact("Alderwood Mine")
	check(world.area=="Mine" and game.model.s.mine.depth==1,"enter from grove")
	game.interact("Mine descent")
	check(game.model.s.mine.depth==1,"closed descent")
	for depth in range(1,10):
		check(game.model.s.mine.depth==depth,"level %d reachable"%depth)
		for idx in [0,2,3,4]:
			var key:="mine-node:"+str(idx)
			if not world.targets.has(key):continue
			for swing in range(3):
				if world.targets.has(key):hit(key)
			if int(game.model.s.mine.cleared.get(str(depth),0))>=2 and depth>=3:break
		if depth==1:
			check(game.model.qty("coal")>0,"coal mined")
			game.fuel_lantern()
			check(Mine.lit(game.model),"lantern lit")
			await show("the-old-quarry")
		if depth in [3,6,9]:
			game.interact("Mine lift")
			game.reopen_lift()
			game.close_page()
			check(game.model.s.mine.lift==depth,"lift reopened")
		if depth==4:await show("glowcap-caverns")
		if depth==5:
			for attempt in range(3):hit("Shale beetle")
			check(game.model.s.mine.beaten.has("5"),"optional beetle encounter")
		if depth==7:
			world.pos=Vector2(752,343)
			world.tick(0)
			await show("flooded-galleries")
			game.interact("Underground fishing")
			catch_center()
			check(game.model.qty("cave-char")==1,"cave-exclusive fish")
		game.model.change("soup",2)
		game.eat_in_mine("soup")
		game.eat_in_mine("soup")
		if depth<9:game.interact("Mine descent")
	check(game.model.s.mine.best==9,"deepest floor recorded")
	game.ride_lift(3)
	check(game.model.s.mine.depth==3,"lift returns to bookmarked level")
	game.store()
	check(game.model.load_game() and game.model.s.mine.depth==3 and game.model.s.mine.lift==9,"depth, nodes and lift reload")
	var old_coins:int=game.model.s.coins
	game.model.s.mine.energy=.01
	game._process(.4)
	check(world.area=="Cottage" and game.model.s.coins==old_coins-12,"safe exhaustion with modest penalty")

	world.enter("Arcade",Vector2(321,453))
	game.interact("Ves’s furnace")
	for i in range(2):game.forge("copper-bar")
	check(game.model.qty("copper-bar")>=2,"smelt actual mined copper")
	game.forge("iron-bar")
	check(game.model.qty("iron-bar")>=1,"smelt actual mined iron")
	game.close_page()
	world.enter("Village",Vector2(274,422))
	game.interact("Mara")
	game.dialogue_topic("dock")
	check(game.model.s.mine.dock_stage==3,"Mara accepts lift milestone")
	game.model.change("wood",6)
	game.dialogue_topic("dock")
	check(game.model.s.mine.dock_stage==4 and world.targets.has("Restored fishing dock"),"deliver boards and bars and dock appears")
	game.close_page()
	check(not world.blocked(Vector2(151,391)) and world.blocked(Vector2(151,429)),"walkable dock and adjacent water collision")
	game.model.s.day=game.model.s.mine.supper
	game.model.s.time=1090
	world.tick(0)
	check(world.targets.has("Creekside supper") and world.npcs.Oren.visible,"event and residents present")
	game.toast.hide()
	await show("creekside-supper")
	old_coins=game.model.s.coins
	game.interact("Creekside supper")
	game.interact("Creekside supper")
	check(game.model.s.mine.dock_stage==5 and game.model.s.coins==old_coins+70,"one-time supper reward")

	game.close_page()
	for season in range(1,8):
		game.model.s.day=season*21+14
		game.model.s.time=660
		world.enter("Village",Vector2(630,443))
		check(world.targets.has("Seasonal market"),"market available in season %d"%season)
		var crop:=Market.produce(game.model)
		game.model.change("p"+str(crop),1)
		old_coins=game.model.s.coins
		game.interact("Seasonal market")
		game.seasonal_entry()
		check(game.model.s.coins==old_coins+24,"seasonal reward")
		check(Market.reward(game.model)!="","seasonal reward only once")

	for suffix in ["",".bak"]:DirAccess.remove_absolute(game.model.path_for()+suffix)
	game.music.stop()
	game.fx.stop()
	await create_timer(.65).timeout
	print("Mine and dock regression failures: ",fails)
	quit(1 if fails else 0)

