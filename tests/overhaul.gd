extends SceneTree

const Routes=preload("res://scripts/world_routes.gd")
const Life=preload("res://scripts/world_life.gd")
var game
var world
var failures:=0

func _initialize():
	call_deferred("run")

func check(ok:bool,message:String):
	if not ok:
		failures+=1
		printerr("FAIL: "+message)

func key(code:Key,down:bool):
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func travel(from:Vector2,control:Key):
	world.pos=from
	world.crossing_cooldown=0
	key(control,true)
	world.tick(.065)
	key(control,false)
	world.tick(.016)

func capture(name_:String):
	if DisplayServer.get_name()=="headless":return
	game.update_hud()
	await create_timer(.57).timeout
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://docs/overhaul/"+name_+".png")
	check(root.get_texture().get_image().save_png(path)==OK,"capture "+name_)

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	world=game.world
	game.set_process(false)
	var slot:=810000+randi()%10000
	game.start(slot)
	game.finish_character()
	game.close_page()

	world.pos=Vector2(1030,335)
	world.tick(0)
	game.toast.hide()
	await capture("mill-bridge")
	check(world.blocked(Vector2(1100,302)) and not world.blocked(Vector2(1100,334)),"farm water and deck collision")
	travel(Vector2(1135,330),KEY_D)
	check(world.area=="Village" and world.pos.is_equal_approx(Vector2(34,330)) and world.direction==Vector2.RIGHT,"east across bridge with aligned lane")
	check(world.blocked(Vector2(70,369)) and not world.blocked(Vector2(70,340)),"village water and deck collision")
	travel(Vector2(18,345),KEY_A)
	check(world.area=="Farm" and world.pos.is_equal_approx(Vector2(1118,345)) and world.direction==Vector2.LEFT,"west returns to farm's east edge")
	travel(Vector2(1135,334),KEY_D)
	check(world.area=="Village","return to village")
	game.model.s.time=481
	world.tick(0)
	var oren:Vector2=world.npcs.Oren.position
	check(world.npcs.Oren.visible and not world.blocked(oren) and oren.x<180,"Oren follows deck toward farm")
	game.model.s.time=488
	world.enter("Farm",Vector2(857,334))
	world.tick(0)
	check(world.npcs.Oren.visible and world.npcs.Oren.position.x>1000 and not world.blocked(world.npcs.Oren.position),"Oren continues on far side")
	game.cross_region("Farm","east",Vector2(1138,334))
	game.model.s.time=438
	world.pos=Vector2(533,350)
	world.tick(0)
	game.toast.hide()
	await capture("willowbrook")
	travel(Vector2(737,31),KEY_W)
	check(world.area=="Grove" and world.pos.is_equal_approx(Vector2(737,734)) and world.direction==Vector2.UP,"north stays aligned")
	check(world.blocked(Vector2(400,378)) and not world.blocked(Vector2(405,497)),"pond and south bank collision")
	check(world.blocked(Vector2(467,545)) and not world.blocked(Vector2(454,507)),"outlet collision and walkable stone bridge")
	world.pos=Vector2(434,495)
	world.tick(0)
	game.toast.hide()
	await capture("alderwood-pond")

	check(not Life.hit(game.model,"stone-bank").get("effect",false),"no mining without tool")
	game.model.s.tools["pickaxe"]=true
	game.interact("resource:stone-bank")
	world.tick(.34)
	game.interact("resource:stone-bank")
	check(game.model.qty("stone")==3 and not world.targets.has("resource:stone-bank"),"mine two hits and persist depletion")
	game.model.s.tools["axe"]=true
	for i in range(3):
		world.tick(.34)
		game.interact("resource:alder-west")
	check(game.model.qty("wood")==4 and game.model.qty("cone")==1,"chop alder and gather seeds")
	game.interact("Plant alder seed")
	check(game.model.s.resources.has("nursery") and game.model.qty("cone")==0,"plant a new alder")
	game.store()
	check(game.model.load_game() and Life.remaining(game.model,"stone-bank")==4,"resource depletion survives reload")
	game.model.s.day=7
	world.enter("Grove",Vector2(435,498))
	check(world.targets.has("resource:stone-bank") and world.targets.has("resource:alder-west") and world.targets.has("resource:nursery"),"resources regenerate after enough days")
	game.model.s.time=700
	world.tick(0)
	check(world.npcs.Linn.visible and not world.blocked(world.npcs.Linn.position),"Linn visits the pond")
	game.interact("Fish Alderwood Pond")
	game.fishing_time=game.bite_at+(asin((.61-.5)/.45)+.8)/(float(game.fishing_spec.speed)*2.2)
	await capture("fishing")
	game.reel()
	check(game.model.s.fishing_xp>0 and game.model.s.fish_records.has(game.fishing_spec.id),"catch saves best length and experience")

	travel(Vector2(723,747),KEY_S)
	check(world.area=="Village" and world.pos.is_equal_approx(Vector2(723,39)) and world.direction==Vector2.DOWN,"south returns to village's north edge")
	check(not world.targets.has("Village guesthouse") and world.targets.has("Willowbrook Mercantile"),"no duplicated farmhouse")
	game.model.s.time=400
	game.interact("Willowbrook Mercantile")
	check(world.area=="Village","shop hours enforced")
	game.model.s.time=600
	game.interact("Willowbrook Mercantile")
	check(world.area=="Mercantile","merchant door opens during trade")
	world.pos=Vector2(568,381)
	world.tick(0)
	check(world.npcs.Iona.visible,"merchant on shift")
	await capture("mercantile")
	game.interact("Mercantile counter")
	game.model.s.coins=110
	game.buy_supply("bait",4,"Mercantile counter")
	check(game.model.qty("bait")==1 and game.model.s.coins==106,"counter trade")
	game.close_page()
	game.interact("Leave shop")
	check(world.area=="Village" and world.pos.is_equal_approx(Vector2(355,271)),"return to correct shop threshold")
	game.interact("Fern & Thistle House")
	check(world.area=="Herbarium" and not world.targets.has("Rest until morning"),"resident home separate from farmhouse")
	game.model.s.time=1350
	world.tick(0)
	check(world.npcs.Linn.visible and world.activities.Linn=="Sleeping","Linn returns to their own bed")
	world.pos=Vector2(571,420)
	game.toast.hide()
	await capture("herbarium")
	game.interact("Leave home")
	game.model.s.time=615
	game.interact("The Copper Kettle")
	check(world.area=="Bakery","bakery has separate interior")
	game.interact("Leave shop")
	check(world.area=="Village" and world.pos.is_equal_approx(Vector2(732,275)),"bakery return to correct threshold")

	world.pos=Vector2(480,354)
	world.tick(0)
	game.interact("Linn")
	check(game.page=="Conversation" and game.model.s.bonds.Linn==1,"talk advances friendship")
	await capture("conversation")
	game.dialogue_topic("request")
	check(game.model.s.requests.Linn=="active","request accepted")
	game.model.change("herb",4)
	var coins:int=game.model.s.coins
	game.dialogue_topic("request")
	check(game.model.s.requests.Linn=="done" and game.model.s.coins==coins+27,"request delivery rewarded")
	game.dialogue_topic("request")
	check(game.model.s.coins==coins+27,"request reward is one-time")
	game.give_gift("herb")
	check(game.model.s.moods.Linn[0]=="Happy" and game.model.s.bonds.Linn==7,"favorite gift influences mood and bonds")
	game.dialogue_topic("talk")
	check(game.model.s.friend_events.has("Linn"),"unlocked story tracked")
	game.close_page()
	game.show_page("Requests")
	await capture("requests")
	game.close_page()
	game.store()
	check(game.model.load_game() and game.model.s.requests.Linn=="done" and game.model.s.moods.Linn[0]=="Happy","relationships persist")

	for suffix in ["",".bak"]:
		DirAccess.remove_absolute(game.model.path_for()+suffix)
	game.music.stop()
	game.fx.stop()
	await create_timer(.65).timeout
	print("World overhaul regression failures: ",failures)
	quit(1 if failures else 0)

