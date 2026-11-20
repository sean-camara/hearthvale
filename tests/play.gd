extends SceneTree
var failed:=0
func check(v:bool,msg:String):
	if not v:failed+=1;printerr(msg)
func _initialize():call_deferred("run")
func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var slot:=100000+randi()%80000
	game.start(slot);game.name_edit.text="Aster";game.wardrobe.select(2);game.finish_character();game.close_page()
	check(game.model.s.farmer_name=="Aster" and game.model.s.look==2,"character setup")
	var w=game.world
	var field:=Vector2(287,415)
	w.pos=field-Vector2(0,19);w.direction=Vector2.DOWN
	for i in [0,1,2]:game.select_tool(i);w.act(false)
	check(game.model.s.soil.get("0,0",{}).get("crop",-1)==0,"tool actions did not plant")
	var e:=InputEventKey.new();e.physical_keycode=KEY_D;e.keycode=KEY_D;e.pressed=true;Input.parse_input_event(e)
	await create_timer(.14).timeout
	e.pressed=false;Input.parse_input_event(e);await process_frame
	check(w.pos.x>field.x,"movement failed")
	check(w.blocked(Vector2(335,216)) and w.blocked(Vector2(1040,511)) and not w.blocked(Vector2(1040,332)),"cottage or river collision")
	game.interact("Cottage");check(w.area=="Cottage","interior transition")
	game.interact("Rest until morning");game.dawn();game.interact("Leave cottage")
	w.pos=field-Vector2(0,19);w.direction=Vector2.DOWN;game.select_tool(2);w.act(false);game.dawn()
	game.select_tool(3);w.act(false);check(game.model.qty("p0")==1,"ripe harvest through world")
	game.interact("Storage chest");game.transfer("p0",true);game.transfer("p0",false)
	game.close_page();game.interact("Shipping bin");game.ship("p0");game.close_page();game.dawn()
	check(game.model.s.coins==33,"payment from UI")
	game.interact("Seed market");game.buy_seed(1);game.adopt();check(game.model.s.hen,"adopt from market")
	game.interact("Bramble the hen");game.feed();game.dawn();game.collect_egg();check(game.model.qty("egg")==1,"hen cycle")
	game.cross_region("Farm","east",Vector2(1138,334));game.interact("Iona");game.close_page()
	game.interact("Creek mint 1");game.interact("Creek mint 2");game.model.s.time=480;game.interact("The Copper Kettle");game.interact("Hearth kitchen");game.cook("tea")
	check(game.model.qty("tea")==1,"cook from gathered ingredients")
	game.interact("Leave shop");check(w.area=="Village","correct exit to village")
	game.cross_region("Village","west",Vector2(14,334));game.to_title();game.start(slot);check(game.model.qty("tea")==1 and game.model.s.hen,"continue slot")
	game.close_page()
	game.interact("Fallen branch 1");game.make_decor("fence");game.place_decor("fence")
	w.pos=Vector2(728,382);w.direction=Vector2.DOWN;w.act(false)
	check(game.model.s.decor.size()==1 and game.model.qty("fence")==0,"craft and place")
	game.interact("Fish the creek");game.fishing_time=game.bite_at+(asin((.61-.5)/.45)+.8)/(float(game.fishing_spec.speed)*2.2);game.reel()
	check(game.model.s.catches.size()==1,"timed fishing catch")
	game.model.s.day=6;game.model.change("p0",1);game.cross_region("Farm","east",Vector2(1138,334))
	check(w.targets.has("Seedwake seed fair") and w.npcs.size()==8,"fair appears and eight villagers spawn")
	for person in game.model.village.residents:
		game.interact(person.id);check(game.page=="Conversation" and game.model.s.bonds.has(person.id),"dialogue "+person.id);game.close_page()
	game.model.change("p0",1);game.interact("Seedwake seed fair");game.fair_entry()
	check(game.model.s.get("fair_day")==6,"fair entry");game.close_page()
	game.show_page("Valley map");game.switch_map();check(game.map_region=="Farm","interactive map");game.close_page()
	game.cross_region("Village","west",Vector2(14,334))
	for x in range(5):
		for y in range(2):
			game.model.s.soil["%d,%d"%[x,y]]={"crop":(x+y)%3,"age":x,"wet":true}
	w.refresh_soil();game.toast.hide()
	w.pos=Vector2(381,310);w.direction=Vector2.DOWN;w.tick(0)
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/farm-in-game.png"))
	for suffix in ["",".bak"]:DirAccess.remove_absolute(game.model.path_for()+suffix)
	game.music.stop();game.fx.stop();await create_timer(.65).timeout
	print("Gameplay integration failures: ",failed)
	quit(1 if failed else 0)

