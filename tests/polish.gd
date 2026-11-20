extends SceneTree

var failures:=0
var game
var world

func _initialize():
	call_deferred("run")

func check(ok:bool, label:String):
	if not ok:
		failures+=1
		printerr("FAIL: "+label)

func capture(name_:String):
	if game.active:game.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://docs/polish/"+name_+".png")
	check(root.get_texture().get_image().save_png(output)==OK,"captured "+name_)

func interact_key():
	for down in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=KEY_E
		event.physical_keycode=KEY_E
		event.pressed=down
		root.push_input(event,true)
	await process_frame

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	world=game.world
	game.set_process(false)
	await capture("title")
	game.start(560000+randi()%30000)
	game.finish_character()
	game.close_page()
	world.tick(0)
	game.feedback("Welcome to your homestead.")
	await capture("farm")

	world.pos=Vector2(343,304)
	world.tick(0)
	check(world.near=="Cottage","approach the farmhouse entrance")
	await interact_key()
	check(world.area=="Cottage","enter cottage via interaction key")
	game.toast.hide()
	world.tick(0)
	await capture("cottage")
	check(world.blocked(Vector2(448,417)) and not world.blocked(Vector2(563,422)),"furniture collision and clear aisle")
	world.pos=Vector2(404,352)
	world.tick(0)
	await interact_key()
	check(game.page=="Rest","bed accepts interaction")
	game.close_page()
	world.pos=Vector2(719,325)
	world.tick(0)
	await interact_key()
	check(game.page=="Hearth kitchen","kitchen accepts interaction")
	await capture("kitchen")
	game.close_page()
	world.pos=Vector2(577,497)
	world.tick(0)
	await interact_key()
	check(world.area=="Farm","leave cottage via interaction key")

	var cell:="2,0"
	game.model.s.soil[cell].wet=false
	world.refresh_soil()
	world.pos=Vector2(348,395)
	world.direction=Vector2.DOWN
	game.select_tool(2)
	world.act(false)
	check(world.pending_wet and game.model.s.soil[cell].wet,"water persists as soon as action is accepted")
	check(world.stalks[cell][0].texture==world.tex["bed-dry"],"ground stays dry until water lands")
	world.tick(.283)
	check(world.tool_sprite.visible and world.watering.destination==Vector2(352,421),"can and droplets aim at selected bed")
	await capture("watering")
	world.tick(.112)
	check(world.stalks[cell][0].texture==world.tex["bed-wet"],"bed darkens on impact")
	game.select_tool(0)
	world.tick(.50)
	check(not world.tool_sprite.visible and not world.pending_wet,"pour finishes even after changing selected tool")
	world.pos=Vector2(284,395)
	world.direction=Vector2.DOWN
	game.select_tool(2)
	world.act(false)
	check(not world.pending_wet,"unprepared bed does not trigger a pour")

	game.cross_region("Farm","east",Vector2(1138,334))
	world.pos=Vector2(532,340)
	world.tick(0)
	game.toast.hide()
	await capture("village")
	game.show_page("Journal")
	await capture("journal")
	game.music.stop()
	game.fx.stop()
	for suffix in ["",".bak"]:
		DirAccess.remove_absolute(game.model.path_for()+suffix)
	await create_timer(.7).timeout
	print("Polish regression failures: ",failures)
	quit(1 if failures else 0)

