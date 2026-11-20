extends SceneTree

const Model=preload("res://scripts/farm_state.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
var game
var checks:=0
var failures:=0

func _initialize():call_deferred("run")

func check(ok:bool,label:String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+label)

func screen(label:String):
	await process_frame
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP")+"/hearth-menus-"+label+".png")

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(903000+randi()%7000)
	game.finish_character()
	game.close_page()
	var m=game.model
	m.s.time=630
	m.s.coins=500
	m.change("p0",7)
	m.change("wood",5)
	m.change("dew-tonic",2)
	game.show_page("Journal")
	await screen("journal")
	var journal:Panel=game.overlay.get_child(1)
	var journal_width:=journal.size.x
	check(journal.size.y<510,"journal fits navigation")
	game.show_page("Old south orchard")
	await screen("orchard")
	var compact:Panel=game.overlay.get_child(1)
	check(compact.size.y<390 and compact.size.x<journal_width,"orchard fits short contents")
	game.show_page("Satchel")
	await screen("satchel")
	var grid:GridContainer
	for child in game.modal_box.get_children():
		if child is GridContainer:grid=child
	check(is_instance_valid(grid) and grid.get_child_count()==m.s.bag.size(),"satchel item grid")
	if is_instance_valid(grid):
		grid.get_child(0).pressed.emit()
		check(game.page=="Satchel item","open item detail")
	game.world.enter("Arcade",Vector2(584,466))
	game.open_arcade_counter("Farm Supply")
	await screen("market")
	var model:=Model.new()
	model.s.coins=100
	model.s.time=600
	for tile in ["0,0","2,1","5,3","10,4"]:model.work(tile,0)
	check(Stock.purchase(model,"Farm Supply",3,1)=="","buy field sprinkler")
	for tile:String in model.s.soil:
		check(model.s.soil[tile].wet,"waters prepared bed "+tile)
	model.work("2,4",0)
	check(model.s.soil["2,4"].wet,"also waters newly turned ground")
	model.overnight()
	for tile:String in model.s.soil:
		check(model.s.soil[tile].wet,"daily coverage "+tile)
	game.close_page()
	game.world.enter("Forest",Vector2(703,539))
	game.update_hud()
	await screen("sign")
	game.world.enter("Plains",Vector2(701,525))
	game.update_hud()
	await screen("wagon")
	var texture:Texture2D=game.world.tex["forest-lodge"]
	var image:=texture.get_image()
	check(image.get_pixel(0,0).a==0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a==0,"clear lodge corners")
	var path:String=m.path_for()
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
	game.music.stop()
	game.fx.stop()
	game.ambiance.stop()
	await create_timer(.25).timeout
	game.queue_free()
	await process_frame
	print("%d menu and watering checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

