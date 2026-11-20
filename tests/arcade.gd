extends SceneTree

const Rooms=preload("res://scripts/arcade_rooms.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
var game
var world
var errors:=0

func _initialize():
	call_deferred("run")

func check(condition:bool,name_:String):
	if not condition:
		errors+=1
		printerr("FAIL: "+name_)

func shot(name_:String):
	if DisplayServer.get_name()=="headless":return
	game.update_hud()
	await create_timer(.43).timeout
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://docs/arcade/"+name_+".png")
	check(root.get_texture().get_image().save_png(path)==OK,"capture "+name_)

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	world=game.world
	game.set_process(false)
	var slot:=870000+randi()%8000
	game.start(slot)
	game.finish_character()
	game.close_page()
	world.enter("Farm",Vector2(865,331))
	world.tick(0)
	await shot("route-sign")
	game.cross_region("Farm","east",Vector2(1138,334))
	world.pos=Vector2(970,354)
	game.model.s.time=450
	game.interact("Willowbrook Arcade")
	check(world.area=="Village","arcade closed early")
	game.model.s.time=945
	world.tick(0)
	game.toast.hide()
	await shot("arcade-exterior")
	game.interact("Willowbrook Arcade")
	check(world.area=="Arcade","open mall door")
	world.tick(0)
	check(world.npcs.Iona.visible and world.npcs.Oren.visible and world.npcs.Ves.visible,"scheduled arcade shifts")
	await shot("arcade-interior")
	game.model.s.coins=500
	for name_:String in Stock.STORES:
		var anchor:Vector2=world.targets.get("counter:"+name_,Vector2.ZERO)
		check(anchor!=Vector2.ZERO and not world.blocked(anchor),"reachable "+name_)
		check(world.schedules.path(Vector2(577,480),anchor).size()>0,"walk to "+name_)
		world.pos=anchor+Vector2(0,9)
		world.tick(0)
		check(world.near=="counter:"+name_,"interact with "+name_)
		game.interact(world.near)
		check(game.page=="Arcade counter","open catalog "+name_)
		game.select_arcade_item(0)
		check(game.page=="Purchase","product detail "+name_)
		if name_=="Tackle Shop":await shot("purchase")
		var count:SpinBox=null
		for node in game.modal_box.get_children():
			if node is SpinBox:count=node
		check(count!=null,"quantity widget "+name_)
		if name_=="Tackle Shop":count.value=2
		var before:int=game.model.s.coins
		game.finish_arcade_purchase(count)
		check(game.model.s.coins<before and game.page=="Arcade counter","complete purchase "+name_)
		game.close_page()
	check(game.model.qty("bait")==6 and game.model.qty("garden-pot")==1,"bundle and decor received")
	check(game.model.s.tools.get("axe",false),"purchased working tool")
	check(Stock.purchase(game.model,"Farm Supply",3,1)=="","sprinkler purchased")
	game.model.s.soil["0,1"]={"crop":-1,"age":0,"wet":false}
	game.model.s.arcade_sales["sprinkler"]=1
	game.model.overnight()
	check(game.model.s.soil["0,1"].wet,"purchased sprinkler waters the second row")
	game.model.s.time=945
	var last:int=game.model.s.coins
	check(not Stock.purchase(game.model,"Farm Supply",0,999).is_empty() and game.model.s.coins==last,"invalid quantity has no side effect")
	game.store()
	check(game.model.load_game() and game.model.s.area=="Arcade" and game.model.s.arcade_sales.has("sprinkler"),"stock and location survive reload")
	game.interact("Leave arcade")
	check(world.area=="Village" and world.pos.is_equal_approx(Vector2(982,339)),"mall exit returns to its door")

	for name_:String in Rooms.HOMES:
		world.enter(name_,Vector2(577,480))
		check(world.targets.has("Household ledger") and not world.blocked(world.pos),"habitable "+name_)
		for person:String in Rooms.BEDS:
			if world.schedules.HOME[person]!=name_:continue
			var bed:Vector2=Rooms.BEDS[person]
			check(world.schedules.path(Vector2(577,498),bed).size()>0,"path to "+person+"'s bed")
		world.tick(0)
		if name_ in ["Herbarium","CraftsHouse","RiverLodge"]:await shot(name_.to_lower())
	for resident:String in world.resident_heads:
		var atlas:Texture2D=world.resident_heads[resident]
		check(atlas.get_size()==Vector2(352,208),"four aligned rows for "+resident)
		var art:=atlas.get_image()
		for row in range(4):
			var unique:Dictionary={}
			for f in range(6):
				var tile:=art.get_region(Rect2i(f*44,row*52,44,52))
				unique[tile.get_data().hex_encode()]=true
				check(tile.get_used_rect().size.y>=35,"full figure "+resident)
			check(unique.size()>=4,"walk cycle frames differ for "+resident)
	world.enter("Cottage",Vector2(578,478))
	game.apply_arcade_item("home-rug")
	check(game.model.s.furnishings.get("home-rug",false) and game.model.qty("home-rug")==0,"furniture installs from satchel")
	for suffix in ["",".bak"]:DirAccess.remove_absolute(game.model.path_for()+suffix)
	game.music.stop()
	game.fx.stop()
	await create_timer(.55).timeout
	print("Arcade and animation checks failed: ",errors)
	quit(1 if errors else 0)

