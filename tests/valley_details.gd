extends SceneTree

const Details=preload("res://scripts/valley_details.gd")
const Controls=preload("res://scripts/valley_controls.gd")
var game
var w
var failures:=0
var checks:=0

func _initialize():call_deferred("run")

func check(ok:bool,msg:String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL "+msg)

func capture(label:String):
	game.update_hud()
	game.toast.hide()
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP")+"/hv3-"+label+".png")

func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.start(975000+randi()%9000)
	game.finish_character()
	game.begin_first_morning()
	w=game.world
	var m=game.model
	var art:={}
	for season in 8:
		m.s.day=season*21
		w.enter("Farm",Vector2(530,335))
		var pear:=false
		for node in w.actors.get_children():
			if node is Sprite2D and node.texture==w.tex["pear-"+str(season)]:pear=true
		check(pear,"seasonal pear "+str(season))
		art[w.tex["pear-"+str(season)].resource_path]=true
	check(art.size()==8,"unique seasonal art")
	await capture("farm")
	for area:String in Details.FLOORS:
		w.enter(area,Vector2(574,443))
		var found:=false
		for layer in w.low_detail.get_children():
			if layer is Sprite2D and layer.region_enabled and layer.texture.resource_path.ends_with("floor-"+str(Details.FLOORS[area])+".png"):found=true
		check(found,area+" floor")
		if area in ["Bakery","Cottage","Shop:Tool & Hardware"]:await capture(area.replace(":","-"))
	for area:String in game.Routes.OUTDOORS:
		check(not Details.route_hint("Farm",area).is_empty(),area+" route")
	check(Details.route_hint("Farm","Coast").contains("east") and Details.route_hint("Village","Coast").contains("south"),"pin changes next exit")
	w.enter("Village",Vector2(355,275))
	game.show_page("Valley map")
	game.pin_destination("Mercantile")
	game.close_page()
	game.update_hud()
	check(game.marker.text.contains("Mercantile"),"pin appears during play")
	game.inspect_tool("axe")
	check(game.page=="Tool preview","equipment preview")
	await capture("preview")
	game.show_page("Comfort")
	game.toggle_comfort("large-print")
	game.toggle_comfort("steady-camera")
	var sample:Label=game.lbl("Read",20)
	check(sample.get_theme_font_size("font_size")==23,"larger text")
	sample.free()
	check(Controls.assign(m,"Interact",KEY_F) and Controls.equivalent(m,KEY_F)==KEY_E,"remap interact")
	check(not Controls.assign(m,"Map",KEY_F),"duplicate binding rejected")
	game.store()
	check(m.load_game() and Controls.code(m,"Interact")==KEY_F and m.s.expansion.projects.pin=="Mercantile","saved pin and bindings")
	game.close_page()
	w.enter("Farm",Vector2(905,432))
	game.start_fishing("river",true)
	game._process(game.bite_at+.7)
	await capture("fishing")
	game.reel()
	check(game.toast.text.contains("First catch") and w.tex.has("catch-"+w.fishing.species),"species first catch")
	w.enter("Coast",Vector2(839,461))
	m.s.time=1110
	w.tick(.1)
	await capture("shore")
	for id:String in Details.PROPS:
		var sheet:Texture2D=w.work_poses[id]
		check(sheet.get_width()==96 and sheet.get_height()==48,id+" has three occupation frames")
	m.s.day=0
	m.s.time=600
	w.enter("Bakery",Vector2(624,370))
	game.interact("Pip")
	game._process(.02)
	game._process(.5)
	var pip:Sprite2D=w.npcs.Pip
	var working:Sprite2D=pip.get_node_or_null("WorkingPose")
	check(is_instance_valid(working) and working.visible and working.frame==2,"baker settles before conversation")
	await capture("baker-talk")
	game.close_page()
	var save:String=m.path_for()
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(save+suffix)
	game.music.stop()
	game.ambiance.stop()
	game.fx.stop()
	game.queue_free()
	await process_frame
	print("%d valley detail checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

