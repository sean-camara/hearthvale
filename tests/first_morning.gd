extends SceneTree

var game
var w
var failures:=0
var checks:=0

func _initialize():
	call_deferred("run")

func check(ok:bool,msg:String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+msg)

func walk(at:Vector2):
	var path:PackedVector2Array=w.schedules.path(w.pos,at)
	check(not path.is_empty(),"walkable route in "+w.area+" to "+str(at))
	if not path.is_empty():w.pos=path[-1]

func use(id:String):
	if not w.targets.has(id):
		check(false,"missing target "+id)
		return
	var at:Vector2=w.targets[id]
	walk(at+Vector2(0,16))
	var hit:String=w.clicked_interaction(at-Vector2(0,10))
	check(hit==id,"click "+id+" reached "+hit)
	game.interact(hit)

func button(prefix:String):
	for node in game.modal_box.get_children():
		if node is Button and node.text.begins_with(prefix):
			node.pressed.emit()
			return
	check(false,"missing action "+prefix)

func cross(side:String,at:Vector2):
	walk(at)
	game.cross_region(w.area,side,at)

func capture(id:String):
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP")+"/hearth-"+id+".png")

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	w=game.world
	var m=game.model
	game.start(950000+randi()%5000)
	game.finish_character()
	game.begin_first_morning()
	use("Seed parcel")
	use("Leave cottage")
	cross("east",Vector2(1138,334))
	use("Willowbrook Mercantile")
	check(w.area=="Village","closed shop gives opening hours")
	m.s.time=496
	use("Willowbrook Mercantile")
	use("Mercantile counter")
	button("Axe")
	check(m.s.coins==6 and game.purchase_status.text.contains("garden bench"),"first purchase gives direction and payoff")
	game.close_page()
	use("Leave shop")
	cross("north",Vector2(733,29))
	for i in 3:
		w.tick(.4)
		use("resource:alder-west")
	check(m.qty("wood")==4,"logs for bench")
	game.show_page("Workshop")
	button("Build Garden bench")
	check(m.qty("bench")==1 and m.qty("wood")==0,"craft from first tree")
	game.close_page()
	cross("south",Vector2(733,746))
	cross("west",Vector2(14,334))
	w.tick(0)
	use("Oren")
	var lessons:Array=game.overlay.find_children("*","Button",true,false)
	await capture("practice")
	var lesson_found:=false
	for option in lessons:
		if option.text=="Practice cast":
			lesson_found=true
			option.pressed.emit()
			break
	check(lesson_found,"Oren offers lesson at creek")
	if lesson_found:
		game._process(game.bite_at+.8)
		check(game.fishing_status.text=="Reel now!","coached bite window")
		game.reel()
		check(m.qty(w.fishing.species)==1 and w.tex.has("catch-"+w.fishing.species),"species art matches catch")
	game.close_page()
	use("Cottage")
	use("Rest until morning")
	button("Sleep until")
	check(m.s.day==1 and m.load_game() and m.qty("bench")==1,"next morning persists")
	w.enter("Coast",Vector2(586,404))
	use("Old tide steps")
	check(m.s.expansion.projects.has("steps-sketch") and not m.s.expansion.projects.has("shell-carving"),"submerged steps sketched")
	m.s.day=84
	m.s.time=750
	use("Old tide steps")
	check(m.s.expansion.projects.has("shell-carving"),"Goldleaf low tide reveals keepsake")
	w.enter("Village",Vector2(957,477))
	m.s.time=600
	m.change("p0",1)
	use("Player market stall")
	button("Set out "+m.item_name("p0"))
	check(game.page=="Market customer" and m.s.expansion.projects.get("last-sale-Tavi")=="p0","resident inspects purchase")
	await create_timer(1.2).timeout
	await capture("market")
	await create_timer(2.0).timeout
	check(game.page=="Player market stall","market returns after customer")
	game.close_page()
	game.interact("Tavi")
	check(game.dialogue_text.text.contains(m.item_name("p0")),"customer remembers purchase")
	var file:String=m.path_for()
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(file+suffix)
	game.music.stop()
	game.fx.stop()
	game.ambiance.stop()
	game.queue_free()
	await process_frame
	print("%d first morning checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)


