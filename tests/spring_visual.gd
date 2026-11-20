extends SceneTree

var failures:=0
func check(result:bool,what:String):
	if not result:
		failures+=1
		printerr("FAIL: "+what)

func snap(game,name_:String):
	game.update_hud()
	game.world.tick(0)
	await process_frame
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	check(pic.get_size()==Vector2i(1280,720),"native review resolution")
	pic.save_png(ProjectSettings.globalize_path("res://docs/spring/"+name_+".png"))

func _initialize():call_deferred("run")
func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var test_slot:=300000+randi()%50000
	game.start(test_slot)
	game.finish_character()
	game.close_page()
	var w=game.world
	game.feedback("Welcome to your homestead.")
	await snap(game,"arrival")
	check(w.actors.y_sort_enabled,"foot anchors use Y sorting")
	check(w.paths.get_used_cells().size()==864,"separate path tile layer")
	check(w.hen_sprite!=null and not game.model.s.hen,"visiting hen is visible")
	check(w.stalks.size()==8,"inherited crops have live plot sprites")
	var front:Vector2=w.hen_sprite.position
	w.tick(.4)
	check(w.hen_sprite.position.distance_to(front)>0,"hen wanders")
	w.pos=Vector2(429,382);w.tick(0)
	check(w.near=="Storage chest","chest interaction at sprite base")
	game.interact(w.near);check(game.page=="Storage chest","chest opens");game.close_page()
	w.pos=Vector2(679,339);w.tick(0)
	check(w.near=="Seed market","stall interaction at counter")
	game.interact(w.near);check(game.page=="Seed market","stall opens");await snap(game,"seed-market");game.close_page()
	game.model.change("p5",3);game.model.change("p3",2)
	game.model.s.day=4
	# Show growth states in a populated test save. The arrival capture uses the actual new-game state.
	for x in range(1,10):
		for y in range(3):
			var kind:int=[0,0,3,3,5,5,2,4,11][x-1]
			game.model.s.soil["%d,%d"%[x,y]]={"crop":kind,"age":int(game.model.crops[kind].days) if y<2 else 1,"wet":(x+y)%3==0}
	w.refresh_soil();w.pos=Vector2(447,350);game.feedback("Welcome back to the valley.")
	await snap(game,"morning")
	w.pos=Vector2(445,429);game.toast.hide();game.select_tool(3)
	await snap(game,"garden")
	game.store();var saved:int=game.model.s.soil.size()
	game.to_title();game.start(test_slot)
	check(game.model.s.soil.size()==saved and w.stalks.size()==saved,"all planted tiles reload")
	game.model.s.day=90
	game.model.s.upgrades={"library":true,"cistern":true,"kettle":true}
	w.enter("Farm",Vector2(447,350));game.toast.hide()
	check(w.targets.has("The seed library") and w.targets.has("The preserving hearth") and w.targets.has("The rain cistern"),"all restored facilities are interactive")
	await snap(game,"goldleaf")
	game.interact("The seed library");game.claim_packet();check(game.model.s.packet_period==4,"live seasonal seed library")
	game.model.s.day=151
	w.enter("Farm",Vector2(447,350));game.toast.hide()
	await snap(game,"starfrost")
	game.music.stop();game.fx.stop()
	await create_timer(.7).timeout
	for suffix in ["",".bak"]:DirAccess.remove_absolute(game.model.path_for()+suffix)
	print("Spring visual regression failures: ",failures)
	quit(1 if failures else 0)

