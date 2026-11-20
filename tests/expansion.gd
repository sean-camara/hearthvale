extends SceneTree

const Expansion=preload("res://scripts/expansion.gd")
const Play=preload("res://scripts/expansion_play.gd")
const Routes=preload("res://scripts/world_routes.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
var game
var world
var failures:=0
var checks:=0

func _initialize():
	call_deferred("run")

func check(ok:bool,what:String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+what)

func render(region:String,at:Vector2):
	if DisplayServer.get_name()=="headless":return
	game.close_page()
	world.enter(region,at)
	game.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://docs/expansion/"+region.to_lower().replace(":","-").replace(" & ","-").replace(" ","-")+".png")
	check(root.get_texture().get_image().save_png(path)==OK,"render "+region)

func reachable(from:Vector2,to:Vector2)->bool:
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(2,4,141,90)
	grid.cell_size=Vector2(8,8)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.position.y,grid.region.end.y):
		for x in range(grid.region.position.x,grid.region.end.x):
			var cell:=Vector2i(x,y)
			grid.set_point_solid(cell,world.blocked(Vector2(cell)*8))
	var start:=Vector2i((from/8).round()).clamp(grid.region.position,grid.region.end-Vector2i.ONE)
	for offset in [Vector2(0,28),Vector2(25,0),Vector2(-25,0),Vector2(0,-23),Vector2.ZERO]:
		var end:=Vector2i(((to+offset)/8).round()).clamp(grid.region.position,grid.region.end-Vector2i.ONE)
		if not grid.is_point_solid(start) and not grid.is_point_solid(end) and not grid.get_id_path(start,end).is_empty():return true
	return false

func catch_fish():
	game.fishing_time=game.bite_at+(asin((.61-.5)/.45)+.8)/(float(game.fishing_spec.speed)*2.2)
	game.reel()

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	world=game.world
	var model=game.model
	var slot:=880000+randi()%10000
	game.start(slot)
	game.finish_character()
	game.begin_first_morning()
	check(world.area=="Cottage" and world.targets.has("Seed parcel"),"new player wakes by seed parcel")
	game.interact("Seed parcel")
	var count:int=model.qty("s0")
	game.interact("Seed parcel")
	check(count==8 and model.qty("s0")==count,"seed parcel collected once")
	game.interact("Bedside almanac")
	check(game.page=="Bedside almanac","almanac opens")
	game.close_page()
	game.interact("Leave cottage")
	var field:=Vector2(287,415)
	world.pos=field-Vector2(0,19)
	world.direction=Vector2.DOWN
	for tool in [0,1,2]:
		game.select_tool(tool)
		world.act(false)
		world.tick(.8)
	check(model.s.expansion.lessons.size()==3 and model.s.soil["0,0"].wet,"hoe, sow, water record on real farm")
	game.dawn()
	world.pos=field-Vector2(0,19)
	world.direction=Vector2.DOWN
	world.act(false)
	world.tick(.8)
	game.dawn()
	check(model.weather(model.s.day)=="Showers" and model.s.soil["0,0"].wet,"first rainy morning waters beds")
	world.pos=field-Vector2(0,19)
	world.direction=Vector2.DOWN
	game.select_tool(3)
	world.act(false)
	check(model.s.expansion.first_harvest and model.qty("p0")>0,"harvest")
	game.interact("Oren")
	check(model.s.expansion.oren_note and game.page=="Conversation","Oren responds to invitation")
	game.close_page()
	game.interact("Fish the creek")
	var fish:String=game.fishing_spec.id
	catch_fish()
	model.change("herb",1)
	Play.cook_chowder(game,fish)
	check(model.qty("creek-soup")==1 and model.s.expansion.finds.has(fish),"rain fishing, cook, sketchbook")
	game.close_page()
	game.interact("Linn")
	game.give_gift("p0")
	game.close_page()
	model.s.time=1110.0
	game.interact("Fern & Thistle House")
	game.interact("Linn")
	check(game.page=="Linn’s supper","Linn’s evening invitation")
	Play.linn_supper(game)
	check(model.qty("soup")==2 and model.s.expansion.linn_cooked,"Linn's soup is shared")
	game.close_page()
	world.enter("Village",Vector2(210,362))
	model.s.day=0
	game.interact("Creek pottery")
	check(model.qty("creek-pottery")==1,"low creek discovery")
	Play.exhibit(game)
	check(model.s.expansion.projects.archive and model.qty("creek-pottery")==0,"archive exhibit")
	game.close_page()
	model.s.day=2

	for region:String in ["Village","Grove"]+Expansion.NAMES.keys():
		for side:String in Expansion.LINKS.get(region,{}):
			var exit:Vector2={"north":Vector2(885,25),"south":Vector2(885,752),"east":Vector2(1139,610),"west":Vector2(12,610)}[side]
			var motion:Vector2={"north":Vector2.UP,"south":Vector2.DOWN,"east":Vector2.RIGHT,"west":Vector2.LEFT}[side]
			world.enter(region,Vector2(875,659))
			check(Routes.edge(region,exit,motion)==side and not world.blocked(exit),region+" "+side+" walkable exit")
			check(reachable(Vector2(875,659),exit-motion*16),region+" "+side+" reachable from route")
			game.cross_region(region,side,exit)
			var expected:Array=Expansion.LINKS[region][side]
			check(world.area==expected[0] and not world.blocked(world.pos),region+" "+side+" enters "+expected[0])
		if not Expansion.NAMES.has(region):continue
		world.enter(region,Vector2(885,670))
		for target:String in ["travel:find","travel:fish","travel:landmark"]:
			if world.targets.has(target):check(reachable(world.pos,world.targets[target]),region+" "+target+" reachable")
		check(model.s.expansion.visited.has(region),region+" recorded in atlas")
		if Expansion.FISHING.has(region):
			game.interact("travel:fish")
			check(game.page=="Creek fishing",region+" fishing overlay")
			catch_fish()

	world.enter("Coast",Vector2(885,471))
	model.s.time=360
	check(not Expansion.gather(model,"Coast").begins_with("Found"),"high tide covers shells")
	model.s.time=780
	game.interact("travel:find")
	check(model.qty("tide-shell")==1,"low tide exposes shell")
	check(not Expansion.gather(model,"Coast").begins_with("Found"),"shell replenishes next day")
	model.change("wood",24)
	model.change("stone",14)
	model.change("copper-bar",2)
	Play.project(game,"ferry",{"wood":8,"copper-bar":2},"Lighthouse ferry")
	check(model.s.expansion.projects.ferry and model.qty("copper-bar")==0,"ferry repair")
	Play.travel(game,"Isles",Vector2(888,510))
	game.interact("travel:find")
	check(model.qty("moon-fruit")==1,"island produce")
	world.enter("Desert",Vector2(590,480))
	Play.project(game,"oasis",{"stone":6,"wood":2},"Oasis irrigation")
	game.close_page()
	model.s.time=1070
	game.interact("travel:find")
	check(model.qty("glassbloom")==1,"dusk oasis bloom")
	Play.project(game,"greenhouse",{"wood":8,"stone":4},"Greenhouse")
	Play.greenhouse(game,"glassbloom")
	model.s.day+=3
	Play.greenhouse(game,"glassbloom")
	check(model.qty("glassbloom")==2,"greenhouse cutting matures")
	Play.collect_honey(game,"orchard")
	model.s.day+=2
	Play.collect_honey(game,"orchard")
	Play.collect_honey(game,"herbs")
	model.s.day+=2
	Play.collect_honey(game,"herbs")
	check(model.qty("blossom-honey")==1 and model.qty("herb-honey")==1,"two honey profiles")
	model.s.time=550
	Play.sell_stall(game,"blossom-honey")
	Play.sell_stall(game,"blossom-honey")
	check(model.s.expansion.stall_sales.size()==1,"market distinct sales")
	game.close_page()

	model.s.time=600
	world.enter("Arcade",Vector2(576,486))
	for title:String in Stock.STORES:
		check(reachable(world.pos,world.targets["shop:"+title]),"entrance to "+title)
		game.interact("shop:"+title)
		check(world.area=="Shop:"+title and reachable(world.pos,world.targets["counter:"+title]),"department "+title)
		game.interact("counter:"+title)
		check(game.page=="Arcade counter","counter "+title)
		game.close_page()
		game.interact("Leave department")
		check(world.area=="Arcade" and not world.blocked(world.pos),"return from "+title)
	world.enter("Frost",Vector2(450,558))
	game.interact("Frostpine ice cave")
	check(world.area=="IceCave" and reachable(world.pos,world.targets["Ice quartz"]),"reachable ice cave quartz")
	model.s.tools.pickaxe=true
	game.interact("Ice quartz")
	check(model.qty("ice-quartz")==1,"mine ice quartz")
	game.interact("Ice cave fishing")
	catch_fish()
	check(model.qty("frost-ray")==1,"ice cave fish")
	game.interact("Leave ice cave")
	check(world.area=="Frost","return from ice cave")

	model.s.mine.depth=9
	game.go_mine(9)
	game.interact("Forgotten passage")
	check(world.area=="Mine","forgotten passage gated")
	model.s.mine.lift=9
	model.s.mine.cleared["9"]=2
	game.interact("Forgotten passage")
	check(world.area=="Below","forgotten passage reached")
	Play.waterfall(game)
	check(world.area=="Lakes" and model.s.expansion.projects.waterfall,"waterfall shortcut")
	game.store()
	check(model.load_game() and model.s.area=="Lakes" and model.s.expansion.projects.ferry,"new region and progression reload")
	for region:String in ["Lakes","Coast","Forest","Marsh","Plains","Desert","Highlands","Frost","Isles","Below"]:
		await render(region,Expansion.LANDMARKS[region][2]+Vector2(0,77))
	await render("IceCave",Vector2(591,447))
	await render("Shop:Flowers & Garden",Vector2(576,478))
	var path:String=model.path_for()
	for suffix:String in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
	game.music.stop()
	game.ambiance.stop()
	game.fx.stop()
	await create_timer(.22).timeout
	game.queue_free()
	await process_frame
	print("%d expansion checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)


