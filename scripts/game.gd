extends Node2D

const Model=preload("res://scripts/farm_state.gd")
const Valley=preload("res://scripts/valley.gd")
const SeasonEvents=preload("res://scripts/season_events.gd")
const Mine=preload("res://scripts/mine_progress.gd")
const Travelers=preload("res://scripts/traveling_residents.gd")
const Expansion=preload("res://scripts/expansion.gd")
const HomesteadLife=preload("res://scripts/homestead_life.gd")
const MenuCards=preload("res://scripts/menu_cards.gd")
var satchel_filter:="All"
var satchel_item:=""
var satchel_caption:=""
var satchel_count:=0
const Projects=preload("res://scripts/village_projects.gd")
const ExpansionPlay=preload("res://scripts/expansion_play.gd")
const Routes=preload("res://scripts/world_routes.gd")
const Rooms=preload("res://scripts/arcade_rooms.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
const Life=preload("res://scripts/world_life.gd")
const Dialogue=preload("res://scripts/resident_dialogue.gd")
const Atlas=preload("res://scripts/atlas.gd")
const Controls=preload("res://scripts/valley_controls.gd")
const Details=preload("res://scripts/valley_details.gd")
var binding:=""
var map_region:=""
var purchase_tool:="axe"
var marker:=Label.new()
var last_route:=""
const TOOLS=["Hoe","Seeds","Water","Harvest"]
const IVORY=Color("#f8edd5")
const MINT=Color("#c4d9b2")
var model=Model.new()
var world=Valley.new()
var layer:=CanvasLayer.new()
var ui:=Control.new()
var hud:=Control.new()
var overlay:=Control.new()

var title_screen:=Control.new()

var toast:Label
var context:Label
var clock_label:Label
var area_label:Label
var modal_box:VBoxContainer
var farm_hud=preload("res://scripts/farm_hud.gd").new()
var practice_cast:=false
var fishing_time:=0.0
var fishing_track:Control
var fishing_status:Label
var fishing_button:Button
var purchase_status:Label
var baited:=false
var tonic_cast:=false
var active := false
var closing:=false
var page := ""
var name_edit:LineEdit
var pronoun_edit:LineEdit
var wardrobe:OptionButton
var toast_left:=0.0
var save_left:=0.0
var speaker:Dictionary={}
var introducing:=false
var dialogue_text:Label
var dialogue_tween:Tween
var ferry_fade:ColorRect
var flyover:Tween
var arrow_cursor:=Input.CURSOR_ARROW
var mine_meter:Label
var beetle_hits:=0
var arcade_shop:=""
var arcade_item:=0
var arcade_feedback:=""
var fishing_spec:Dictionary={}
var fishing_site:="river"
var bite_at:=0.0
var music:=AudioStreamPlayer.new()
var ambiance:=AudioStreamPlayer.new()
var ambient_key:=""
var fx:=AudioStreamPlayer.new()
const BODY_FONT=preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
var serif:=FontVariation.new()
var sans:=FontVariation.new()

func _ready():
	add_child(ambiance)
	get_tree().auto_accept_quit=false
	serif.base_font=preload("res://assets/fonts/Baskervville.ttf")
	serif.variation_opentype={"weight":600}
	sans.base_font=BODY_FONT
	var game_theme:=Theme.new()
	game_theme.default_font=sans
	game_theme.default_font_size=18
	for kind in ["LineEdit","OptionButton"]:
		game_theme.set_stylebox("normal",kind,style(Color("#382820"),Color("#a27b54"),12))
		game_theme.set_stylebox("focus",kind,style(Color("#382820"),Color("#f1ce91"),12))
	ui.theme=game_theme
	add_child(world);world.setup(model);world.visible=false
	world.used.connect(interact)
	world.crossed.connect(cross_region)
	world.step_message.connect(feedback)
	marker.add_theme_font_override("font",sans)
	marker.add_theme_constant_override("outline_size",5)
	marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
	place(hud,marker,25,159)
	Input.set_custom_mouse_cursor(load("res://assets/valley/cursor.png"),Input.CURSOR_ARROW,Vector2.ZERO)
	Input.set_custom_mouse_cursor(load("res://assets/valley/point.png"),Input.CURSOR_POINTING_HAND,Vector2(6,0))
	add_child(layer);layer.add_child(ui);ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for c in [hud,title_screen,overlay]:
		ui.add_child(c);c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);c.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ferry_fade=ColorRect.new()
	ferry_fade.size=Vector2(1280,720)
	ferry_fade.color=Color("#182420")
	ferry_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ferry_fade.modulate.a=0
	ui.add_child(ferry_fade)
	add_child(music);add_child(fx)
	music.stream=preload("res://assets/meadow.wav");music.volume_db=-8
	music.finished.connect(func(): if model.s.sound: music.play())
	menu()
	build_hud()
	hud.hide()
	overlay.hide()
	music.play()

func style(bg:Color,edge:Color,margin:int=10)->StyleBoxFlat:
	var st:=StyleBoxFlat.new();st.bg_color=bg;st.border_color=edge
	st.set_border_width_all(1);st.set_corner_radius_all(5)
	st.content_margin_left=margin;st.content_margin_right=margin;st.content_margin_top=margin*.65;st.content_margin_bottom=margin*.65
	return st

func keycap(text:String)->Label:
	if active:
		var action:String={"Space":"Work / reel","E":"Interact","M":"Map","J":"Journal","C":"Workshop","I":"Satchel"}.get(text,"")
		if action!="":text=Controls.name_for(model,action)
	var label:=lbl(text,14,Color("#37241a"))
	label.add_theme_stylebox_override("normal",style(Color("#f0d6a5"),Color("#ba9562"),6))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func panel(parent:Control,at:Vector2,sz:Vector2,color:=Color("#233d35ef"))->Panel:
	var p:=Panel.new();parent.add_child(p);p.position=at;p.size=sz
	p.add_theme_stylebox_override("panel",style(color,Color("#81917b"),0))
	return p

func lbl(text:String,size_:int=20,color:=IVORY,display:=false)->Label:
	if active and size_<=23 and model.s.expansion.projects.get("large-print",false):size_+=3
	var l:=Label.new();l.text=text;l.add_theme_font_override("font",serif if display else sans);l.add_theme_font_size_override("font_size",size_);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func place(parent:Control,l:Control,x:int,y:int):
	parent.add_child(l);l.position=Vector2(x,y)

func btn(text:String,fn:Callable)->Button:
	var b:=Button.new();b.text=text;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size=Vector2(100,40)
	b.add_theme_font_override("font",sans);b.add_theme_font_size_override("font_size",20 if active and model.s.expansion.projects.get("large-print",false) else 18)
	for k in ["normal","hover","pressed","focus"]:
		var col=Color("#375348") if k=="normal" else Color("#4a6957")
		b.add_theme_stylebox_override(k,style(col,Color("#a3ad89") if k!="normal" else Color("#667d68"),14))
	b.add_theme_color_override("font_color",IVORY)
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.pressed.connect(fn)
	return b

func clear_children(c:Node):
	for child in c.get_children():c.remove_child(child);child.queue_free()

func menu():
	active=false
	world.hide()
	hud.hide()
	overlay.hide()
	title_screen.show()
	clear_children(title_screen)
	var landscape:=preload("res://assets/valley.png")
	var bg:=farm_hud.stamp(title_screen,landscape,Vector2.ZERO,Vector2(1280,720))
	bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size=Vector2(1280,720)
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,.55,1.0])
	gradient.colors=PackedColorArray([Color("#171f19fa"),Color("#25261de5"),Color("#25261d00")])
	var shade:=GradientTexture2D.new()
	shade.gradient=gradient
	shade.fill_to=Vector2.RIGHT
	var veil:=farm_hud.stamp(title_screen,shade,Vector2.ZERO,Vector2(845,720))
	veil.stretch_mode=TextureRect.STRETCH_SCALE
	veil.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR

	farm_hud.stamp(title_screen,farm_hud.textures.leaf,Vector2(64,48),Vector2(35,35))
	title_rule(Vector2(110,66),104)
	var title:=lbl("Hearthvale",91,IVORY,true)
	title.add_theme_color_override("font_shadow_color",Color("#150d07ba"))
	title.add_theme_constant_override("shadow_offset_y",3)
	place(title_screen,title,61,75)
	place(title_screen,lbl("The Eight Seasons",33,Color("#efd6a6"),true),68,181)

	place(title_screen,lbl("Choose your homestead",25,IVORY,true),68,269)
	var preview:=Model.new()
	for i in range(1,4):
		preview.slot=i
		var has_save:=FileAccess.file_exists(preview.path_for()) or FileAccess.file_exists(preview.path_for()+".bak")
		var details:=""
		var recap:=""
		if has_save:
			if preview.load_game():
				var day:=int(preview.s.day)
				details="%s  ·  %s %d, Year %d"%[str(preview.s.farmer_name).replace("\n"," "),Model.SEASONS[preview.season()],day%21+1,floori(day/168.0)+1]
				if preview.s.expansion.projects.get("crafted-bench",false):recap="You built a garden bench."
				elif not preview.s.catches.is_empty():recap="Your field book holds %d fish species."%preview.s.catches.size()
				else:recap="Your seed parcel awaits." if not preview.s.expansion.parcel else "Your first garden is underway."
			else:details="Save could not be read"
		menu_slot(i,has_save,details,recap)
	var quit:=btn("Leave the valley",quit_game)
	quit.add_theme_stylebox_override("normal",style(Color("#231d19dc"),Color("#a68256"),15))
	quit.add_theme_stylebox_override("hover",style(Color("#443024"),Color("#d8b27a"),15))
	quit.add_theme_stylebox_override("pressed",style(Color("#2e221c"),Color("#d8b27a"),15))
	place(title_screen,quit,68,601)

func title_rule(at:Vector2,width:int):
	var rule:=ColorRect.new()
	rule.color=Color("#c4a16f")
	rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rule.size=Vector2(width,1)
	title_screen.add_child(rule)
	rule.position=at

func menu_slot(index:int,has_save:bool,details:String,recap:String=""):
	var card:=Button.new()
	card.custom_minimum_size=Vector2(399,76)
	card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	card.pressed.connect(start.bind(index))
	card.add_theme_stylebox_override("normal",farm_hud.plates.wood)
	var hover:StyleBoxTexture=farm_hud.plates.wood.duplicate()
	hover.modulate_color=Color("#fff3ca")
	var pressed:StyleBoxTexture=farm_hud.plates.wood.duplicate()
	pressed.modulate_color=Color("#d8bd9c")
	card.add_theme_stylebox_override("hover",hover)
	card.add_theme_stylebox_override("pressed",pressed)
	var focus:=style(Color.TRANSPARENT,Color("#f6d59c"),0)
	focus.draw_center=false
	focus.set_border_width_all(2)
	card.add_theme_stylebox_override("focus",focus)
	place(title_screen,card,65,311+(index-1)*87)
	var emblem:Texture2D=world.tex.homestead if has_save else farm_hud.textures.leaf
	var badge:TextureRect=farm_hud.stamp(card,emblem,Vector2(15,17),Vector2(51,42))
	badge.size=Vector2(51,42)
	var heading:=lbl("Farm %d"%index,23,IVORY,true)
	place(card,heading,79,12 if has_save else 24)
	if has_save:
		var line:=lbl(details,14,Color("#e2c8a2"))
		line.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		line.size.x=205
		place(card,line,79,34)
		if recap!="":place(card,lbl(recap,13,Color("#e9c587")),79,52)
	var action:=lbl("Continue" if has_save else "New farm",15,Color("#382619"))
	action.add_theme_stylebox_override("normal",farm_hud.plates.slot)
	action.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	action.size=Vector2(92,33)
	place(card,action,289,21)

func build_hud():
	farm_hud.build(self)
	mine_meter=lbl("",17,IVORY)
	mine_meter.add_theme_stylebox_override("normal",farm_hud.plates.wood)
	place(hud,mine_meter,16,155)
	mine_meter.hide()

func start(slot:int):
	model.slot=slot
	var exists:=FileAccess.file_exists(model.path_for()) or FileAccess.file_exists(model.path_for()+".bak")
	if exists and not model.load_game():
		var existing:=title_screen.get_node_or_null("SaveError")
		if existing==null:
			var err:=lbl("This farm could not be read. Choose another slot.",16,Color("#ffe3ad"))
			err.name="SaveError"
			place(title_screen,err,68,578)
		return
	if not exists:
		model.reset()
		model.s.x=448.0
		model.s.y=346.0
		# A small inherited garden gives the first season a living baseline.
		for spec in [[2,0,0,1],[3,0,0,2],[4,0,1,2],[5,0,1,3],[6,0,2,3],[7,0,2,4],[2,1,11,1],[3,1,11,2]]:
			model.s.soil["%d,%d"%[spec[0],spec[1]]]={"crop":spec[2],"age":spec[3],"wet":true}
	world.enter(model.s.area,Vector2(model.s.x,model.s.y))
	active=true;world.show();hud.show();title_screen.hide();page="";overlay.hide();apply_audio();update_hud();select_tool(0)
	apply_look()
	introducing=not exists
	if introducing:show_page("Meet your farmer")
	else:feedback("Welcome back to the valley.")

func store()->bool:
	model.s.x=world.pos.x;model.s.y=world.pos.y
	return model.save_game()

func finish_character():
	var name_:String=name_edit.text.strip_edges()
	model.s.farmer_name=name_ if name_!="" else "Rowan"
	model.s.pronouns=pronoun_edit.text.strip_edges()
	model.s.look=wardrobe.selected
	apply_look()
	store()
	if introducing:
		introducing=false
		show_page("Arrival")
	else:close_page()
func apply_look():
	var sprites=["farmer","farmer-clay","farmer-indigo"]
	world.normal_farmer=load("res://assets/spring/"+sprites[clampi(int(model.s.look),0,2)]+".png")
	world.work_farmer=load("res://assets/seasons/worker-"+str(clampi(int(model.s.look),0,2))+".png")
	world.runner.texture=world.normal_farmer
func begin_first_morning():
	model.s.expansion.intro=true
	model.s.soil["1,0"]={"crop":-1,"age":0,"wet":false}
	relocate("Cottage",Vector2(430,362),Vector2.DOWN)
	close_page()
	feedback("A seed parcel waits by the door. Press E to open it.")

func refresh_ambiance():
	var wind:bool=world.area in ["Plains","Desert","Highlands","Frost"]
	var key:String="rain" if model.weather(model.s.day)=="Showers" else ""
	if world.area in ["Mine","Below","IceCave"]:key="cave"
	elif key=="":
		if world.area in ["Coast","Lakes","Isles","Marsh"]:key="shore"
		elif world.area in ["Forest","Grove"]:key="woods"
		elif wind:key="wind"
	var indoors:bool=world.area not in Routes.OUTDOORS
	ambiance.volume_db=-32 if indoors and key=="rain" else -19
	ambiance.pitch_scale=.77 if indoors and key=="rain" else 1.0
	if key==ambient_key:return
	ambient_key=key
	ambiance.stop()
	if key=="" or not model.s.sound:return
	var stream:AudioStreamWAV=load("res://assets/expansion/"+key+".wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_end=stream.get_data().size()/2
	ambiance.stream=stream
	
	ambiance.play()

func apply_audio():
	music.stream_paused=not model.s.sound
	if model.s.sound and not music.playing:music.play()
	ambiance.stop()
	ambient_key=""
	if active:refresh_ambiance()

func select_tool(i:int):
	world.tool=i
	if active and page=="":update_hud()

func feedback(msg:String,play_sound:bool=true):
	toast.text=msg;toast.show();toast_left=3.8
	if play_sound and model.s.sound:
		fx.stop()
		fx.pitch_scale=1
		if msg.begins_with("Watered"):fx.stream=preload("res://assets/polish/pour.wav")
		elif msg.begins_with("Found") or msg.contains("× Moonstone"):
			fx.stream=load("res://assets/expansion/rare.wav")
		elif msg.begins_with("Harvested"):fx.stream=preload("res://assets/harvest.wav")
		else:fx.stream=preload("res://assets/work.wav")
		fx.volume_db=-12;fx.play()

func update_hud():
	var dest:String=model.s.expansion.projects.get("pin","")
	var route_key:String=world.area+"|"+dest
	if route_key!=last_route:
		last_route=route_key
		marker.text=(Routes.NAMES.get(dest,dest)+" · "+Details.route_hint(world.area,dest)) if dest!="" else ""
	marker.position.y=210 if world.area=="Mine" else 162
	area_label.text=Routes.NAMES[world.area]
	mine_meter.visible=world.area=="Mine"
	if world.area=="Mine":
		area_label.text=Mine.title(int(model.s.mine.depth))
		mine_meter.text="Level %d   ·   %d energy   ·   %s"%[model.s.mine.depth,ceili(model.s.mine.energy),"Lantern lit" if Mine.lit(model) else "Unlit"]
	var minutes:=int(model.s.time)
	var hour:=floori(minutes/60.0)
	var hour12:=hour%12 if hour%12>0 else 12
	clock_label.text="%s %d   ·   %02d:%02d %s   ·   %s   ·   %d %s"%[Model.SEASONS[model.season()],int(model.s.day)%21+1,hour12,minutes%60,"AM" if hour<12 else "PM",model.weather(model.s.day),model.s.coins,"crown" if model.s.coins==1 else "crowns"]
	farm_hud.update_context(self)
	farm_hud.update(self)

func _process(dt):
	if active and page=="Creek fishing":
		var previous:=fishing_time
		fishing_time+=dt
		if model.s.sound and previous<bite_at and fishing_time>=bite_at:
			fx.pitch_scale=1
			fx.stream=load("res://assets/expansion/bite.wav")
			fx.volume_db=-11
			fx.play()
		world.fishing.update(world,dt,fishing_time>=bite_at)
		refresh_fishing_panel()
	if active and page in ["Conversation","Arcade counter","Mercantile counter","Purchase","Tool preview"]:
		world.elapsed+=dt
		world.refresh_people()
		world.marks.queue_redraw()
	if not active or page!="":return
	var before_impact:float=world.impact_left
	world.tick(dt)
	if model.s.sound and before_impact>.18 and world.impact_left<=.18:
		fx.stream=preload("res://assets/work.wav")
		fx.volume_db=-12
		fx.pitch_scale=1.18 if world.impact_stone else .84
		fx.play()
	refresh_ambiance()
	music.volume_db=move_toward(music.volume_db,-25 if world.sitting else -16,dt*20)
	if world.area=="Mine" and Mine.exhausted(model):
		evacuate_mine()
		return
	model.s.time+=dt*float(model.s.speed)*.85
	if model.s.time>=1440:
		dawn()
	update_hud();toast_left-=dt
	if toast_left<=0:toast.hide()
	save_left+=dt
	if save_left>=45:store();save_left=0

func dawn():
	var earned:int=model.s.shipping
	var underground:bool=world.area in ["Mine","SlateSpur","FloodedSpur"]
	HomesteadLife.overnight(model)
	model.overnight()
	if underground:world.enter("Cottage",Vector2(420,365))
	else:world.enter(world.area,world.pos)
	store();close_page();feedback("Morning in the valley. Shipping earned %d crowns."%earned)

func _input(e):
	if active and page=="Controls" and binding!="" and e is InputEventKey and e.pressed and not e.echo:
		_unhandled_input(e)

func _unhandled_input(e):
	if not active or page=="Market customer":return
	if e is InputEventMouseMotion:
		world.cursor_mode=true
		world.update_focus()
		var shape:=Input.CURSOR_POINTING_HAND if page=="" and world.clicked_interaction(world.get_global_mouse_position())!="" else Input.CURSOR_ARROW
		if shape!=arrow_cursor:
			arrow_cursor=shape
			Input.set_default_cursor_shape(shape)
	if e is InputEventKey and e.pressed and not e.echo:
		if page=="Controls" and binding!="":
			if e.keycode==KEY_ESCAPE:binding=""
			elif Controls.assign(model,binding,e.physical_keycode):
				binding=""
				store()
			show_page("Controls")
			get_viewport().set_input_as_handled()
			return
		var key:=Controls.equivalent(model,e.physical_keycode)
		if page=="Creek fishing" and key==KEY_SPACE:
			reel();get_viewport().set_input_as_handled();return
		if page=="Conversation" and key in [KEY_SPACE,KEY_E]:
			if dialogue_tween!=null and dialogue_tween.is_running():
				dialogue_tween.kill()
				dialogue_text.visible_ratio=1.0
			else:dialogue_topic("talk")
			get_viewport().set_input_as_handled()
			return
		if e.keycode==KEY_ESCAPE and world.placing!="":world.placing="";feedback("Placement cancelled.");return
		if e.keycode==KEY_ESCAPE:
			if page=="":show_page("Pause")
			else:close_page()
			get_viewport().set_input_as_handled();return
		if page!="":return
		match key:
			KEY_1,KEY_2,KEY_3,KEY_4:select_tool(e.physical_keycode-KEY_1)
			KEY_5,KEY_6,KEY_7,KEY_8,KEY_9:farm_hud.quick_action(self,e.physical_keycode-KEY_1)
			KEY_E:
				if world.near!="":interact(world.near)
				else:world.act(false)
			KEY_SPACE:world.cursor_mode=false;world.update_focus();world.act(false)
			KEY_I:show_page("Satchel")
			KEY_J:show_page("Journal")
			KEY_M:map_region="";show_page("Valley map")
			KEY_C:show_page("Workshop")
			KEY_W,KEY_A,KEY_S,KEY_D:world.cursor_mode=false
	elif e is InputEventMouseButton and e.pressed and page=="":
		if e.button_index==MOUSE_BUTTON_LEFT:world.act(true)
		elif e.button_index==MOUSE_BUTTON_RIGHT:
			if world.placing!="":world.placing="";feedback("Placement cancelled.")
			else:show_page("Satchel")

func interact(id:String):
	if HomesteadLife.handle(self,id) or Projects.handle(self,id) or ExpansionPlay.handle(self,id):return
	if id.begins_with("mine-node:"):
		if world.area!="Mine" or world.impact_left>.12:return
		var result:=Mine.strike(model,int(model.s.mine.depth),int(id.get_slice(":",1)))
		if result.get("effect",false):
			if result.get("done",false):world.enter("Mine",world.pos)
			if result.get("done",false):
				var ore:String=Mine.nodes(int(model.s.mine.depth))[int(id.get_slice(":",1))].ore
				Expansion.record(model,ore,Mine.title(int(model.s.mine.depth)))
			world.impact_ore=Mine.nodes(int(model.s.mine.depth))[int(id.get_slice(":",1))].ore
			world.mine_strike(result.at)
			store()
		if result.has("message"):feedback(result.message,not result.get("effect",false))
		if Mine.exhausted(model):evacuate_mine()
		return
	if id.begins_with("shop:"):
		if not Stock.is_open(model):feedback("The arcade opens from 09:00 to 19:00.")
		else:relocate("Shop:"+id.trim_prefix("shop:"),Vector2(576,478),Vector2.UP)
		return
	if id=="Leave department":
		var stock:Dictionary=Stock.STORES[world.area.trim_prefix("Shop:")]
		relocate("Arcade",stock.at+Vector2(-52,25),Vector2.DOWN)
		return
	if id.begins_with("counter:"):
		open_arcade_counter(id.trim_prefix("counter:"))
		return
	if id.begins_with("resource:"):
		var resource_id:=id.trim_prefix("resource:")
		if world.impact_left>.12:return
		var result:=Life.hit(model,resource_id)
		if result.get("effect",false):
			if result.get("depleted",false):world.enter(world.area,world.pos)
			world.strike(resource_id)
			store()
		feedback(result.get("message",""),not result.get("effect",false))
		return
	if Travelers.PEOPLE.has(id):
		speaker=Travelers.PEOPLE[id]
		model.record_visit(id)
		dialogue_topic("greeting")
		return
	for person in model.village.residents:
		if id==person.id:
			speaker=person
			model.record_visit(person.id)
			if person.id=="Linn" and model.s.expansion.linn_supper and not model.s.expansion.linn_cooked and world.area=="Herbarium" and float(model.s.time)>=1080.0:
				show_page("Linn’s supper")
				return
			if person.id=="Oren" and model.s.expansion.intro and int(model.s.day)>=1 and not model.s.expansion.oren_note:
				model.s.expansion.oren_note=true
				store()
				render_dialogue("I left a note by your bed. Walk down to the creek where it bends past your farm. On rainy days the trout come closer to the bank.","Happy")
				return
			dialogue_topic("greeting")
			return
	match id:
		"Alderwood Mine":
			if not model.s.tools.get("pickaxe",false):feedback("Buy a pickaxe at the arcade or mercantile before descending.")
			else:go_mine(1)
		"Mining kit","Ves’s furnace","Mine lift":show_page(id)
		"Mine descent":
			if Mine.descend(model):go_mine(int(model.s.mine.depth))
			else:feedback("This is the deepest gallery." if int(model.s.mine.depth)>=Mine.DEPTHS else "Clear two deposits here to uncover the descent.")
		"Leave mine":relocate("Grove",Mine.EXIT,Vector2.DOWN)
		"Shale beetle":fight_beetle()
		"Underground fishing":start_fishing("mine")
		"Restored fishing dock":start_fishing("river")
		"Frostpine ice cave":enter_building("IceCave")
		"Ice cave fishing":start_fishing("ice-cave")
		"Ice quartz":
			if model.s.picked.get("ice-quartz",-1)==model.s.day:feedback("Check again tomorrow.")
			elif not model.s.tools.get("pickaxe",false):feedback("Bring a pickaxe to free the ice quartz.")
			elif model.change("ice-quartz",1):
				model.s.picked["ice-quartz"]=model.s.day
				Expansion.record(model,"ice-quartz","Frostpine Ice Cave")
				world.mine_strike(world.targets[id])
				store()
				feedback("Found ice quartz.")
		"Leave ice cave":relocate("Frost",Routes.DOORS.IceCave[2],Vector2.DOWN)
		"Creekside supper":
			if Mine.supper(model):
				store()
				show_page("Creekside supper")
			elif int(model.s.mine.dock_stage)==5:show_page("Creekside supper")
			else:feedback(Mine.dock_status(model))
		"Seedwake seed fair":show_page("Seed fair")
		"Seasonal market":show_page("Seasonal market")
		"Bridge to Willowbrook":feedback("Follow the bridge east to Willowbrook.")
		"Bridge to Hearthvale":feedback("Follow the bridge west to Hearthvale.")
		"Alderwood trail":feedback("The path north leads to Alderwood Grove.")
		"Trail to Willowbrook":feedback("Follow the path south to Willowbrook.")
		"Cottage":enter_building("Cottage")
		"Willowbrook Mercantile":open_store("Mercantile",480,1140)
		"The Copper Kettle","Village guesthouse":open_store("Bakery",420,1200)
		"Fern & Thistle House":open_home("Herbarium")
		"The Stave House":open_home("CraftsHouse")
		"Oren’s River Lodge":open_home("RiverLodge")
		"Willowbrook Arcade":open_store("Arcade",Stock.HOURS.x,Stock.HOURS.y)
		"Iona’s Seed Loft":open_home("SeedLoft")
		"Pip’s Attic":open_home("BakerLoft")
		"Household ledger","Arcade directory":show_page(id)
		"Leave cottage","Leave shop","Leave home","Leave arcade":
			var door:Array=Routes.DOORS[world.area]
			relocate(door[0],door[2],Vector2.DOWN)
		"Fish the creek","Fish Alderwood Pond":
			start_fishing("pond" if id=="Fish Alderwood Pond" else "river")
		"Plant alder seed":
			if Life.seed(model):
				world.enter(world.area,world.pos)
				store()
				feedback("Alder planted. It should mature in six days.")
			else:feedback("Bring an alder seed from a harvested tree.")
		"Rest until morning":show_page("Rest")
		"Seed market","Iona's seed stall":
			if model.s.time>=1140:feedback("The seed counter opens at 06:00 tomorrow.")
			else:show_page("Seed market")
		"Shipping bin","Storage chest","Hearth kitchen":show_page(id)
		"Mercantile counter","Bakery counter":
			var bakery:=id=="Bakery counter"
			if model.s.time<(420 if bakery else 480) or model.s.time>=(1200 if bakery else 1140):feedback("The counter is closed for the day.")
			else:show_page(id)
		"Bramble the hen":show_page("Bramble")
		"The seed library","The rain cistern","The preserving hearth":show_page(id)
		"Meet Bramble":feedback("Bramble belongs to the seed keeper. Ask at the stall about adoption.")
		_:
			if id.begins_with("Fallen branch") and model.change("wood",2):
				model.s.picked[id]=model.s.day;world.enter(world.area,world.pos);feedback("Gathered two lengths of fallen wood.")
			if id.begins_with("Creek mint") and model.change("herb",1):
				model.s.picked[id]=model.s.day;world.enter(world.area,world.pos);feedback("Gathered creek mint.")

func open_store(building:String,opening:int,closing_hour:int):
	if model.s.time>=opening and model.s.time<closing_hour:
		enter_building(building)
	else:
		feedback("Open %02d:00–%02d:00."%[floori(opening/60.0),floori(closing_hour/60.0)])

func open_home(house:String):
	if model.s.time>=480 and model.s.time<1200:
		enter_building(house)
	else:feedback("Visiting hours are 08:00–20:00.")

func enter_building(building:String):
	model.s.erase("door")
	relocate(building,Vector2(576,480),Vector2.UP)

func cross_region(region:String,side:String,where:Vector2):
	var next:=Routes.destination(region,side,where)
	if not next.is_empty():
		relocate(next.area,next.position,next.facing)
		feedback(Routes.NAMES[next.area])

func relocate(region:String,where:Vector2,facing:Vector2):
	world.direction=facing
	world.enter(region,where)
	world.crossing_cooldown=.25
	store()
	if flyover!=null and flyover.is_running():flyover.kill()
	ferry_fade.modulate.a=.36
	flyover=create_tween()
	flyover.tween_property(ferry_fade,"modulate:a",0,.27).set_trans(Tween.TRANS_SINE)

func dialogue_topic(topic:String):
	var id:String=speaker.id
	var mood:=Life.mood(model,id)
	var line:String
	match topic:
		"dock":
			line=Mine.dock_talk(model,id)
			store()
			if world.area=="Village" and int(model.s.mine.dock_stage)>=4 and not world.targets.has("Restored fishing dock"):
				world.enter("Village",world.pos)
		"request":
			line=model.talk(id) if id=="Iona" else Life.mission(model,id)
			store()
		"talk":
			var score:int=model.s.bonds.get(id,0)
			if score>=6 and not model.s.friend_events.has(id):
				model.s.friend_events[id]=int(model.s.day)
				mood="Happy"
				line=Life.INTERESTS.get(id,speaker.get("story",""))+" I’m glad you asked."
				store()
			elif score>=3:line=Life.INTERESTS.get(id,speaker.get("story",""))
			else:line=speaker.greetings[(int(model.s.day)+1)%speaker.greetings.size()]
		_:
			if Life.birthday(model,id):line="It’s my birthday today. It’s good to see you."
			elif int(model.s.day)-int(model.s.expansion.projects.get("sale-date-"+id,-10)) in [0,1] and model.s.expansion.projects.has("last-sale-"+id):
				var item:String=model.s.expansion.projects["last-sale-"+id]
				line="That %s from your stall made my morning. Will you be at the market again?"%model.item_name(item)
			elif Projects.market_memory(model,id)!="":line=Projects.market_memory(model,id)
			elif id=="Iona" and not model.s.expansion.projects.has("market-delivery"):
				line="Bring something for our market supper. Pip needs radishes, Oren will take a catch, and Ves is fixing the lantern. There’s an invitation in your journal."
			elif id=="Oren" and world.area in ["Farm","Village"]:line="Watch the float. A minnow taps twice. A pike pulls the line sideways before it dives."
			elif id=="Soren":line="See the old steps along Sunshore? In Goldleaf and Emberfall the low tide lets you walk down. I used to leave shells there."
			elif model.is_fair():line="Did you see the baskets in the square? Seedwake is my favorite time to meet the new growers."
			elif world.activities.get(id,"").begins_with("Crossing"):line="Keep to the middle of the bridge. The moss grows thick by the railings."
			elif model.weather(model.s.day)=="Showers":
				line="The rain keeps the creek honest. You can hear the river long before you reach the bridge." if id in ["Oren","Linn"] else speaker.greetings[(int(model.s.day)+2)%speaker.greetings.size()]
			else:line=speaker.greetings[int(model.s.day)%speaker.greetings.size()]
	render_dialogue(line,mood)

func render_dialogue(line:String,mood:String):
	page="Conversation"
	world.talking=speaker.id
	world.refresh_people()
	hud.hide()
	clear_children(overlay)
	overlay.show()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	arrow_cursor=Input.CURSOR_ARROW
	Dialogue.new().build(self,speaker,line,mood)

func give_gift(item:String):
	var id:String=speaker.id
	var before:=model.qty(item)
	var response:=Life.gift(model,id,item)
	if id=="Linn" and item=="p0" and model.qty(item)<before and model.s.expansion.first_harvest and not model.s.expansion.linn_supper:
		model.s.expansion.linn_supper=true
		response="This will make a good soup. Come over to Fern & Thistle House after six and we’ll cook together."
	store()
	render_dialogue(response,Life.mood(model,id))

func sketch_entry(text:String,icon:Texture2D):
	var line:=HBoxContainer.new()
	line.add_theme_constant_override("separation",13)
	if icon!=null:
		var drawing:=TextureRect.new()
		drawing.texture=icon
		drawing.custom_minimum_size=Vector2(40,40)
		drawing.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		drawing.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		line.add_child(drawing)
	var caption:=lbl(text,20,Color("#f9e0ae"))
	caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	line.add_child(caption)
	modal_box.add_child(line)

func row(text:String,f:Callable,icon:Texture2D=null):
	var b:=btn(text,f)
	farm_hud.list_button(self,b)
	if icon!=null:
		b.icon=icon
		b.add_theme_constant_override("icon_max_width",32)
		b.add_theme_constant_override("h_separation",12)
	modal_box.add_child(b)

func note(text:String):
	var l:=lbl(text,19,IVORY);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;modal_box.add_child(l)

func close_page():
	binding=""
	if page=="Creek fishing":world.fishing.clear(world)
	world.talking=""
	if page=="Valley map":map_region=""
	page="";overlay.hide();hud.show();get_viewport().gui_release_focus()
	if active:update_hud()

func show_page(id:String):
	world.talking=""
	page=id;hud.hide();clear_children(overlay);overlay.show()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	arrow_cursor=Input.CURSOR_ARROW
	if id=="Creek fishing":
		build_fishing_overlay()
		return
	var dim:=ColorRect.new();dim.color=Color("#11231c91");dim.size=Vector2(1280,720);overlay.add_child(dim)
	var compact:bool=id in ["Rest","Old south orchard","Alderwood footbridge","Linn’s dawn walk","Bramble","Talk","Requests","Satchel item","Mine lift","Bakery counter","South pasture","Tend goat","Tend sheep","Mining kit","Trail shelter","The rain cistern","The seed library","Tool preview","Comfort","Elderwood field lodge","Maelin’s shop","Livestock board","Journal projects","Journal people"]
	var width:=536 if compact else 688
	var p:=farm_hud.plaque(self,overlay,Vector2((1280-width)*.5,53),Vector2(width,614))
	var inset:=panel(p,Vector2(18,17),Vector2(width-36,579))
	inset.mouse_filter=Control.MOUSE_FILTER_IGNORE
	inset.add_theme_stylebox_override("panel",style(Color("#30211b"),Color("#a58156"),0))
	var heading:=lbl(satchel_caption if id=="Satchel item" else id,28 if compact else 34,Color("#f9e0ae"),true)
	heading.size.x=width-214
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	place(p,heading,34,23)
	var rule:=ColorRect.new()
	rule.color=Color("#9c754d")
	rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	place(p,rule,34,79)
	rule.size=Vector2(width-68,1)
	var exit:=btn("Close",close_page)
	farm_hud.paper_button(exit)
	exit.custom_minimum_size.x=116
	place(p,exit,width-151,24)
	place(exit,keycap("Esc"),70,9)
	var scroll:=ScrollContainer.new()
	place(p,scroll,34,94)
	scroll.size=Vector2(width-68,482)
	scroll.follow_focus=true
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var rail:=scroll.get_v_scroll_bar()
	rail.custom_minimum_size.x=9
	rail.add_theme_stylebox_override("scroll",style(Color("#251a15"),Color("#624831"),1))
	for state in ["grabber","grabber_highlight","grabber_pressed"]:
		rail.add_theme_stylebox_override(state,style(Color("#b3895a"),Color("#d3ae79"),4))
	modal_box=VBoxContainer.new();modal_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;modal_box.add_theme_constant_override("separation",8);scroll.add_child(modal_box)
	var fit:=fit_menu.bind(p,inset,scroll,modal_box)
	modal_box.minimum_size_changed.connect(fit.call_deferred)
	fit.call_deferred()
	match id:
		"Meet your farmer":
			note("What should the valley call you?")
			name_edit=LineEdit.new();name_edit.text=model.s.farmer_name;name_edit.max_length=24;modal_box.add_child(name_edit)
			note("Pronouns")
			pronoun_edit=LineEdit.new();pronoun_edit.text=model.s.pronouns;pronoun_edit.max_length=28;modal_box.add_child(pronoun_edit)
			note("Farmer appearance")
			wardrobe=OptionButton.new();modal_box.add_child(wardrobe)
			for look in ["Sage work shirt","Clay work shirt","Indigo work shirt"]:wardrobe.add_item(look)
			wardrobe.select(clampi(int(model.s.look),0,2))
			row("Settle in",finish_character)
		"Arrival":
			var illustration:=TextureRect.new()
			illustration.texture=preload("res://assets/valley.png")
			illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
			illustration.custom_minimum_size=Vector2(550,202)
			modal_box.add_child(illustration)
			note("You arrive at dawn with the key to your grandmother’s cottage. She left a few things growing beside the path and enough seed to make the next row your own.")
			row("Wake up in the cottage",begin_first_morning)
		"Welcome","Field guide":
			note("Your grandmother left seven seed packets and the key to the cottage. The bare beds are just south of the path.")
			note("Walk with WASD or arrows. Hold Shift to run. Work a nearby square by clicking it, or face it and press Space.")
			note("1  Hoe the soil.   2  Sow seeds.   3  Water each growing day.   4  Harvest ripe crops. Breakfast radishes ripen after two watered nights.")
			note("Press E near the cottage door, then E by the bed to sleep. The chest keeps supplies. The slotted shipping bin pays at dawn.")
			note("I opens your satchel to choose seeds. M shows routes. Find Iona across the eastern bridge for your first delivery.")
			row("Return to the valley",close_page)
		"Rest":
			note("Watered crops grow while you sleep. Tomorrow’s forecast is "+model.weather(model.s.day+1)+".")
			if model.s.catches.is_empty():note("Tomorrow you could meet Oren at the farm creek for a casting lesson.")
			elif model.qty("wood")>=4:note("Tomorrow you could build a garden bench. Open the Workshop with C.")
			else:note("Tomorrow the village market opens at 09:00. Bring something you grew or caught.")
			row("Sleep until 06:00",dawn)
		"Satchel":
			MenuCards.satchel(self,satchel_filter)
			for item:String in HomesteadLife.Brews:
				if model.qty(item)>0:row("Use "+model.item_name(item)+" ×"+str(model.qty(item)),HomesteadLife.drink.bind(self,item),farm_hud.product_icon(self,item))
			if world.area=="Mine" and model.s.tools.get("mine-lantern",false) and model.qty("coal")>0:
				row("Fuel lantern with 1 coal",fuel_lantern)
		"Satchel item":
			build_satchel_item()
		"Seed market":
			MenuCards.header(self,"Seasonal seed counter","Wallet · %d crowns"%model.s.coins,world.tex.packet)
			row("Village order book",show_page.bind("Village orders"))
			for i in range(model.crops.size()):
				var c:Dictionary=model.crops[i]
				if model.season() in c.seasons:
					MenuCards.product(self,c.name,int(c.cost),"%d days"%c.days,buy_seed.bind(i),farm_hud.product_icon(self,"p"+str(i)))
			if not model.s.hen:row("Adopt Bramble, a laying hen   ·   28 crowns",adopt)
		"Shipping bin":
			MenuCards.header(self,"Tomorrow’s payment","%d crowns"%model.s.shipping,world.tex.bin)
			var any:=false
			for key in model.s.bag:
				if model.value(key)>0:
					any=true
					MenuCards.product(self,"Ship "+model.item_name(key),model.value(key),"×%d"%model.qty(key),ship.bind(key),farm_hud.product_icon(self,key))
			if not any:note("Bring harvested crops, eggs, meals or creek mint to ship.")
		"Storage chest":
			MenuCards.header(self,"Satchel","Choose a stack to store one item.",farm_hud.textures.satchel)
			for key in model.s.bag:MenuCards.product(self,"Store "+model.item_name(key),-1,"×%d"%model.qty(key),transfer.bind(key,true),farm_hud.product_icon(self,key))
			MenuCards.header(self,"Chest","Choose a stack to take one item.",world.tex.chest)
			for key in model.s.chest:MenuCards.product(self,"Take "+model.item_name(key),-1,"×%d"%model.s.chest[key],transfer.bind(key,false),farm_hud.product_icon(self,key))
		"Mining kit":
			note("Use coal from your satchel to light the lantern. Eat food to recover energy.")
			if not model.s.tools.get("mine-lantern",false):row("Mine lantern  ·  20 crowns",buy_supply.bind("mine-lantern",20,"Mining kit"))
			row("Garden soup  ·  28 crowns",buy_supply.bind("soup",28,"Mining kit"),farm_hud.product_icon(self,"soup"))
		"Mine lift":
			note("Deepest reached  ·  %d of %d"%[model.s.mine.best,Mine.DEPTHS])
			if int(model.s.mine.depth) in [3,6,9] and int(model.s.mine.depth)>int(model.s.mine.lift):
				row("Reopen this lift landing",reopen_lift)
			for landing in [1,3,6,9]:
				if landing<=int(model.s.mine.lift):row("Ride to level %d"%landing,ride_lift.bind(landing))
		"Ves’s furnace":
			note("Ves smelts ore. Tavi uses the bars for equipment.")
			for key:String in Mine.RECIPES:
				var ingredients:=PackedStringArray()
				for item:String in Mine.RECIPES[key]:
					ingredients.append("%d %s"%[Mine.RECIPES[key][item],model.item_name(item)])
				row("%s  ·  %s"%[model.item_name(key) if key!="sprinkler" else "Install field sprinkler",", ".join(ingredients)],forge.bind(key))
		"Dock restoration":
			note(Mine.dock_status(model))
			note("Deepest mine level %d  ·  Lift unlocked through level %d"%[model.s.mine.best,model.s.mine.lift])
			note("The dock stays open after the supper. Completing the project rewards 70 crowns.")
		"Creekside supper":
			note("Pip sets down a basket of warm bread. Mara pulls the last chair up to the table while Oren watches a float drift past the new dock.")
			note("The restored dock is open for fishing. Oren, Mara, and Pip are a little closer to you.")
		"Journal":
			MenuCards.journal(self)
		"Journal projects":
			row("Fieldwork and livestock",show_page.bind("Fieldwork"),world.tex.hay)
			row("Restoration and seasonal notes",show_page.bind("Restoration notes"),world.tex["project-apple"])
			row("Dock restoration",show_page.bind("Dock restoration"),world.tex["mine-dock"])
			row("Village orders and homestead projects",show_page.bind("Village orders"),world.tex.library)
			row("Back to journal",show_page.bind("Journal"))
		"Journal field notes":
			ExpansionPlay.journal(self)
			if not model.s.catches.is_empty():row("Fishing records",show_page.bind("Fishing records"),world.tex["item-rod"])
			row("Field guide",show_page.bind("Field guide"),world.tex.bookcase)
			row("Back to journal",show_page.bind("Journal"))
		"Journal people":
			row("Quests and requests",show_page.bind("Requests"))
			for person:String in model.s.bonds:
				var days:=int(model.s.bonds[person])
				MenuCards.header(self,person,"%d %s together"%[days,"day" if days==1 else "days"])
			row("Back to journal",show_page.bind("Journal"))
		"Fishing records":
			note("Fishing experience  ·  %d"%model.s.fishing_xp)
			for fish:Dictionary in Life.FISH:
				if not model.s.catches.has(fish.id):continue
				var record:Dictionary=model.s.fish_records.get(fish.id,{})
				note("%s  ·  %d caught  ·  %d cm best  ·  %d fine"%[fish.name,model.s.catches[fish.id],record.get("best_cm",0),record.get("fine",0)])

		"Village orders":
			note("%s   ·   %d orders delivered"%[model.home.book.seasons[model.season()][0],model.s.completed_orders.size()])
			note("The village posts three requests each week. New requests arrive in %d days."%(7-int(model.s.day)%7))
			for order in model.home.orders(model):
				if model.s.completed_orders.has(order.key):
					note(order.person+"   ·   Delivered")
				else:
					note(order.story)
					row("%s   ×%d   ·   %d crowns   (%d held)"%[model.item_name(order.item),order.qty,order.reward,model.qty(order.item)],fulfil_order.bind(order.key),farm_hud.product_icon(self,order.item))
			row("Homestead projects",show_page.bind("Homestead projects"))
			row("Seasonal harvest record",show_page.bind("Harvest record"))
		"Harvest record":
			note("Harvest an in-season crop in each of the eight seasons. Your record carries across years.")
			for i in range(8):note(("◆   " if model.s.harvest_book.has(str(i)) else "◇   ")+Model.SEASONS[i])
		"Homestead projects":
			note("Completed orders   ·   %d"%model.s.completed_orders.size())
			for plan in model.home.book.projects:
				note(plan.description)
				if model.s.upgrades.has(plan.id):note(plan.name+"   ·   Restored")
				else:row("%s   ·   %d orders, %d crowns, %d wood"%[plan.name,plan.orders,plan.coins,plan.wood],restore_project.bind(plan.id))
		"The seed library":
			note("The seed keeper leaves four seeds from a crop that grows this season.")
			if int(model.s.packet_period)==floori(float(model.s.day)/21):note("You have this season’s packet.")
			else:row("Collect the seasonal packet",claim_packet)
		"The rain cistern":
			note("The irrigation line waters prepared beds along the northern row every morning.")
		"The preserving hearth":
			if model.s.batch.is_empty():
				note("Simmer three matching crops overnight. Each jar ships for more than the raw produce.")
				var can_cook:=false
				for i in range(model.crops.size()):
					if model.qty("p"+str(i))>=3:
						can_cook=true
						row("Preserve "+model.crops[i].name,simmer_crop.bind(i),farm_hud.product_icon(self,"p"+str(i)))
				if not can_cook:note("Bring three of one harvested crop to start a batch.")
			elif model.s.day>=model.s.batch.ready:row("Collect your preserves",collect_batch)
			else:note("The kettle is simmering. Come back tomorrow morning.")
		"Calendar":
			note("Year %d   ·   Each season lasts 21 days."%(int(model.s.day)/168+1))
			for i in range(8):note(("◆   " if i==model.season() else "◇   ")+Model.SEASONS[i])
			note("Seedwake 7   ·   First Harvest Seed Fair, Willowbrook")
			if model.season()>0:note("%s 15   ·   %s, Willowbrook"%[Model.SEASONS[model.season()],SeasonEvents.TITLES[model.season()]])
			note("Tomorrow   ·   "+model.weather(model.s.day+1))
			for resident in Life.BIRTHDAYS:
				var day:int=Life.BIRTHDAYS[resident]
				note("%s %d  ·  %s’s birthday"%[Model.SEASONS[floori(day/21.0)],day%21+1,resident])
		"Valley map":
			if map_region=="":map_region=Routes.map_region(world.area)
			var atlas:=Atlas.new();modal_box.add_child(atlas);atlas.set_region(map_region,world.area,world.pos)
			var pin:String=model.s.expansion.projects.get("pin","")
			if pin!="":
				note("Pinned · "+Routes.NAMES[pin]+" · "+Details.route_hint(world.area,pin))
				row("Clear pin",pin_destination.bind(""))
			row("Pin "+Routes.NAMES[map_region],pin_destination.bind(map_region),Details.art(Details.emblem(map_region)))
			if map_region=="Village":
				for shop:String in ["Mercantile","Bakery","Arcade"]:
					var hours:String={"Mercantile":"08:00–19:00","Bakery":"07:00–20:00","Arcade":"09:00–19:00"}[shop]
					row("Pin "+Routes.NAMES[shop]+" · "+hours,pin_destination.bind(shop),Details.art(Details.emblem(shop)))
			for region in Routes.OUTDOORS:
				if region!=map_region:row(Routes.NAMES[region],switch_map.bind(region),Details.art(Details.emblem(region)))
			note("Farmstead · Cottage and bed northwest of the seedbeds. Storage and shipping stand beside the beds. The green seed stall is east along the path.")
			note("Willowbrook · Iona works near the village stall. Oren walks the creek bank. Look for mint along the southern side of the road.")
			var routes:=Routes.links(map_region)
			var directions:={"north":"North","south":"South","east":"East","west":"West"}
			for side:String in routes:note("%s · %s"%[directions[side],Routes.NAMES[routes[side][0]]])
			note("You are here   ·   "+Routes.NAMES[world.area])
		"Seasonal market":
			var season:int=model.season()
			note(SeasonEvents.TITLES[season])
			note(SeasonEvents.DESCRIPTIONS[season])
			var crop:=SeasonEvents.produce(model)
			row("Contribute 1 %s  ·  24 crowns and 3 seeds"%model.crops[crop].name,seasonal_entry,farm_hud.product_icon(self,"p"+str(crop)))
		"Seed fair":
			note("On Seedwake 7 the village swaps first harvests. Contribute one Breakfast radish for the fair basket and take home three Sugar pea seeds plus 12 crowns.")
			if int(model.s.get("fair_day",-1))!=int(model.s.day):row("Enter your radish",fair_entry)
			else:note("Your radish is in the village basket.")
		"Gifts":
			note("Choose an item for "+speaker.id+". You can give one gift per day.")
			var available:=false
			if speaker.id=="Linn" and model.qty("p0")>0:
				row("Give a Breakfast radish",give_gift.bind("p0"),farm_hud.product_icon(self,"p0"))
				available=true
			for item in [Life.preference(speaker.id),Life.DISLIKES.get(speaker.id,"")]:
				if model.qty(item)<=0:continue
				available=true
				row("%s  ×%d"%[model.item_name(item),model.qty(item)],give_gift.bind(item),farm_hud.product_icon(self,item))
			if not available:note("You have no suitable gifts in your satchel.")
			row("Return to conversation",dialogue_topic.bind("greeting"))
		"Requests":
			note("Ask residents about work they need help with.")
			if model.s.requests.is_empty():note("No requests accepted yet.")
			for person in model.s.requests:
				var order:=Life.request_for(person)
				if order.is_empty():continue
				var done:bool=model.s.requests[person]=="done"
				note("%s  ·  %s"%[order.title,"Completed" if done else person])
				if not done:note("%d / %d %s  ·  %s  ·  %d crowns"%[mini(model.qty(order.item),order.qty),order.qty,model.item_name(order.item),order.place,order.reward])
		"Arcade directory":
			note("Open 09:00–19:00. Each counter lists its daily stock.")
			for title in Stock.STORES:
				var stall:Dictionary=Stock.STORES[title]
				row("%s  ·  %s  ·  %s row"%[title,stall.keeper,"North" if stall.at.y<400 else "South"],open_department.bind(title))
		"Arcade counter":
			var stall:Dictionary=Stock.STORES[arcade_shop]
			MenuCards.header(self,arcade_shop,"%s’s counter  ·  Wallet %d crowns"%[stall.keeper,model.s.coins],world.tex[stall.art])
			if arcade_feedback!="":note(arcade_feedback)
			var offerings:=Stock.catalog_for(model,arcade_shop)
			for i in range(offerings.size()):
				var item:Array=offerings[i]
				var supply:=Stock.stock(model,item)
				MenuCards.product(self,item[1],int(item[3]),"%d left"%supply if supply>0 else ("Owned" if item[6] else "Sold out"),select_arcade_item.bind(i),arcade_icon(item[0]))
			if arcade_shop=="Tool & Hardware":
				note("Axes and pickaxes are equipped on purchase. Use E or click near a tree or ore deposit in Alderwood Grove.")
				row("Ves’s furnace",show_page.bind("Ves’s furnace"))
			if arcade_shop=="Farm Supply":row("More seasonal seeds",show_page.bind("Seed market"))
			if world.activities.has(stall.keeper):row("Talk to "+stall.keeper,interact.bind(stall.keeper))
		"Tool preview":
			var cost:=int(Life.TOOLS[purchase_tool][1])
			draw_equipment_preview(purchase_tool,cost)
			if not model.s.tools.get(purchase_tool,false) and model.s.coins>=cost:row("Buy for %d crowns"%cost,buy_supply.bind(purchase_tool,cost,"Mercantile counter"))
			row("Back to shop",show_page.bind("Mercantile counter"))
		"Purchase":
			build_purchase_view()
		"Cottage preview":
			build_cottage_preview()
		"Household ledger":
			var names:String=Rooms.OWNERS[world.area]
			note("Residents  ·  "+names)
			for resident in world.activities:note("%s  ·  %s"%[resident,world.activities[resident]])
		"Mercantile counter":
			MenuCards.header(self,"Iona’s counter","Wallet · %d crowns"%model.s.coins,world.tex["general-counter"])
			
			purchase_status=lbl("",17,Color("#debd88"))
			modal_box.add_child(purchase_status)
			for key in ["axe","pickaxe","rod-upgrade"]:
				var tool_spec:Array=Life.TOOLS[key]
				if model.s.tools.get(key,false):note("%s  ·  Owned"%tool_spec[0])
				else:MenuCards.product(self,tool_spec[0],int(tool_spec[1]),"",buy_supply.bind(key,int(tool_spec[1]),"Mercantile counter"),arcade_icon(key))
			for key:String in ["axe","pickaxe","rod-upgrade"]:row("Inspect "+str(Life.TOOLS[key][0]),inspect_tool.bind(key))
			row("Creek bait  ·  4 crowns",buy_supply.bind("bait",4,"Mercantile counter"),farm_hud.product_icon(self,"bait"))
			row("Seasonal seeds",show_page.bind("Seed market"))
		"Bakery counter":
			MenuCards.header(self,"The Copper Kettle","Wallet · %d crowns"%model.s.coins,world.tex["pastry-counter"])
			MenuCards.product(self,"Mint tea",12,"",buy_supply.bind("tea",12,"Bakery counter"),arcade_icon("tea"))
			MenuCards.product(self,"Garden soup",28,"",buy_supply.bind("soup",28,"Bakery counter"),arcade_icon("soup"))
		"Hearth kitchen":
			if model.qty("p0")>0:row("First harvest supper · radish and mint",ExpansionPlay.cook_radish.bind(self))
			for fish:Dictionary in Life.FISH:
				if model.qty(fish.id)>0:
					row("Creek chowder · %s and mint"%fish.name,ExpansionPlay.cook_chowder.bind(self,fish.id))
			note("Cook with ingredients from your satchel. Ship prepared food for crowns.")
			for key in model.village.recipes:
				var parts:=PackedStringArray()
				for ingredient in model.village.recipes[key]:parts.append("%d %s"%[int(model.village.recipes[key][ingredient]),model.item_name(ingredient)])
				row(model.item_name(key)+"   ·   "+", ".join(parts),cook.bind(key),farm_hud.product_icon(self,model.village.recipes[key].keys()[0]))
		"Workshop":
			note("Gather fallen branches along the farm path. Craft a piece, then choose a nearby patch of lawn. Escape cancels placement.")
			note("Wood in satchel   ·   "+str(model.qty("wood")))
			for key in model.workshop:
				var recipe:Dictionary=model.workshop[key]
				var material:String=recipe.get("material","wood")
				row("Build "+model.item_name(key)+"   ·   %d %s"%[int(recipe.get("count",recipe.get("wood",0))),material],make_decor.bind(key))
				if model.qty(key)>0 and world.area=="Farm":row("Place "+model.item_name(key),place_decor.bind(key))
		"Bramble":
			note("A speckled hen scratches around the edge of the beds.")
			row("Feed one seed of the equipped variety",feed)
			if int(model.s.egg_day)==int(model.s.day):row("Gather today’s egg",collect_egg)
		"Comfort":
			row("Text size · "+("Large" if model.s.expansion.projects.get("large-print",false) else "Standard"),toggle_comfort.bind("large-print"))
			row("Impact camera · "+("Steady" if model.s.expansion.projects.get("steady-camera",false) else "Gentle movement"),toggle_comfort.bind("steady-camera"))
			row("Keyboard controls",show_page.bind("Controls"))
		"Controls":
			note("Choose an action, then press a free key. Escape cancels. Arrows and number keys stay available.")
			if binding!="":note("Press a free key for "+binding+".")
			for action:String in Controls.DEFAULTS:row(action+" · "+Controls.name_for(model,action),choose_binding.bind(action))
			row("Restore default keys",reset_bindings)
		"Pause":
			row("Comfort and controls",show_page.bind("Comfort"))
			row("Save homestead",manual_save)
			row("Farmer appearance",show_page.bind("Meet your farmer"))
			row("Day pace   ·   "+("Relaxed" if model.s.speed<1 else "Standard"),toggle_speed)
			row("Sound   ·   "+("On" if model.s.sound else "Off"),toggle_sound)
			row("Field guide",show_page.bind("Field guide"))
			row("Save and return to title",to_title)
			row("Resume",close_page)
		_:
			if not HomesteadLife.page(self,id) and not Projects.page(self,id):ExpansionPlay.page(self,id)

func fit_menu(frame:Panel,inset:Panel,scroll:ScrollContainer,content:VBoxContainer):
	if not is_instance_valid(content) or not is_instance_valid(frame) or content!=modal_box:return
	var body:=clampf(content.get_combined_minimum_size().y+5,54,482)
	var height:=body+124
	frame.size.y=height
	frame.position.y=roundf((720-height)*.5)
	inset.size.y=height-35
	scroll.size.y=body

func filter_satchel(filter:String):
	satchel_filter=filter
	show_page("Satchel")

func inspect_satchel(item:String,caption:String,count:int):
	satchel_item=item
	satchel_caption=caption
	satchel_count=count
	show_page("Satchel item")

func build_satchel_item():
	var item:=satchel_item
	MenuCards.header(self,satchel_caption,"%d in satchel"%satchel_count if satchel_count>0 else "Equipped",arcade_icon(item))
	if Expansion.ITEMS.has(item):note(Expansion.ITEMS[item][2])
	if item.begins_with("s") and item.substr(1).is_valid_int():row("Equip these seeds",equip.bind(item))
	if item in HomesteadLife.Brews:row("Use "+model.item_name(item),HomesteadLife.drink.bind(self,item))
	if model.workshop.has(item) and world.area=="Farm":row("Place "+model.item_name(item),place_decor.bind(item))
	if world.area=="Mine" and Mine.FOOD.has(item):row("Eat · +%d energy"%Mine.FOOD[item],eat_in_mine.bind(item))
	if item=="compost" or Stock.FURNISHINGS.has(item):row("Use "+model.item_name(item),apply_arcade_item.bind(item))
	row("Back to satchel",show_page.bind("Satchel"))

func fulfil_order(key:String):
	if model.home.deliver(model,key):
		store();show_page("Village orders")
	else:note("Bring the requested quantity in your satchel.")
func restore_project(id:String):
	if model.home.restore(model,id):
		world.enter(world.area,world.pos);store();close_page();feedback(model.home.project(id).name+" is ready at the farm.")
	else:note("Finish the listed orders and bring the required wood and crowns.")
func claim_packet():
	if model.home.claim_packet(model):store();close_page();feedback("Added four seasonal seeds to your satchel.")
	else:note("Check your seed stacks for space.")
func simmer_crop(i:int):
	if model.home.simmer(model,i):store();show_page("The preserving hearth")
func collect_batch():
	if model.home.collect(model):store();close_page();feedback("Collected a jar of preserves.")
	else:note("Check your satchel for space.")
func manual_save():
	if store():close_page();feedback("Homestead saved.")
	else:note("Could not write the save. Check available disk space.")

func to_title():
	ambiance.stop()
	ambient_key=""
	if store():menu()
	else:note("Could not write the save.")

func choose_binding(action:String):
	binding=action
	show_page("Controls")

func reset_bindings():
	for action:String in Controls.DEFAULTS:model.s.expansion.projects.erase("bind-"+action)
	binding=""
	store()
	show_page("Controls")

func toggle_comfort(key:String):
	model.s.expansion.projects[key]=not model.s.expansion.projects.get(key,false)
	store()
	show_page("Comfort")

func pin_destination(dest:String):
	model.s.expansion.projects["pin"]=dest
	last_route=""
	store()
	show_page("Valley map")

func toggle_speed():
	model.s.speed=.5 if model.s.speed==1 else 1.0;show_page("Pause")
func toggle_sound():
	model.s.sound=not model.s.sound;apply_audio();show_page("Pause")
func equip(key:String):
	model.s.seed=int(key.substr(1));select_tool(1);close_page();feedback("Equipped "+model.item_name(key)+".")
func buy_seed(i:int):
	if model.buy(i):model.s.seed=i;show_page("Seed market");note("Purchased "+model.crops[i].name+" seeds.")
	else:note("More crowns or satchel space needed.")
func ship(key:String):
	if model.ship(key):show_page("Shipping bin")
func transfer(key:String,deposit:bool):
	if model.transfer(key,deposit):show_page("Storage chest")
func cook(recipe:String):
	if model.cook(recipe):close_page();feedback("Prepared "+model.item_name(recipe)+".")
	else:note("Gather the listed ingredients first.")
func adopt():
	if model.s.coins<model.village.animals.hen.price:note("Bramble costs 28 crowns.");return
	model.s.coins-=int(model.village.animals.hen.price);model.s.hen=true;world.enter(world.area,world.pos);close_page();feedback("Bramble is settling in beside your seedbeds.")
func feed():
	if model.s.fed==model.s.day:note("Bramble has eaten today.");return
	if model.change("s"+str(int(model.s.seed)),-1):model.s.fed=model.s.day;close_page();feedback("Bramble pecks happily. Check for an egg tomorrow.")
	else:note("Bring a packet of seeds.")
func collect_egg():
	if model.s.egg_day==model.s.day and model.change("egg",1):model.s.egg_day=-1;close_page();feedback("Collected a speckled egg.")
func switch_map(region:String=""):
	map_region=region if region!="" else ("Village" if map_region=="Farm" else "Farm")
	show_page("Valley map")
func place_decor(id:String):
	close_page();world.placing=id;feedback("Click nearby grass to place "+model.item_name(id)+".")
func make_decor(id:String):
	if model.craft(id):
		if id=="bench":model.s.expansion.projects["crafted-bench"]=true
		store()
		show_page("Workshop")
	else:note("Check the materials and space in your satchel.")
func fair_entry():
	if not model.is_fair() or int(model.s.get("fair_day",-1))==int(model.s.day):return
	if model.qty("s2")>996 or not model.change("p0",-1):note("Bring a Breakfast radish and leave space for three seeds.");return
	model.change("s2",3);model.s.coins+=12;model.s.fair_day=model.s.day;show_page("Seed fair")
func practice_with_oren():
	close_page()
	start_fishing("river",true)

func start_fishing(site:String,practice:bool=false):
	practice_cast=practice
	fishing_site=site
	var pool:=Life.available(model,site)
	if pool.is_empty():
		feedback("No fish are biting here at this hour.")
		return
	fishing_spec=pool.pick_random()
	world.fishing.species=fishing_spec.id
	fishing_time=0
	baited=not practice and model.change("bait",-1)
	tonic_cast=not practice and model.s.expansion.projects.get("tonic-cast",false)
	if tonic_cast:model.s.expansion.projects.erase("tonic-cast")
	if baited or tonic_cast:store()
	bite_at=.95 if baited else 1.65
	world.fishing.start(world,world.cast_point(site))
	show_page("Creek fishing")

func build_fishing_overlay():
	var frame:Panel=farm_hud.plaque(self,overlay,Vector2(302,510),Vector2(676,180))
	var card:=panel(frame,Vector2(14,15),Vector2(648,150))
	card.add_theme_stylebox_override("panel",style(Color("#30231c"),Color("#9d7750"),0))
	var site:String={"pond":"Alderwood Pond","mine":"Flooded Galleries","river":"Willow Creek"}.get(fishing_site,Routes.NAMES[world.area])
	place(card,lbl(site,29,Color("#f8db9b"),true),18,9)
	place(card,lbl("Oren’s lesson" if practice_cast else ("Baited line" if baited else "Willow rod"),16,Color("#e1c9a6")),485,20)
	fishing_status=lbl("Casting…",19,IVORY)
	place(card,fishing_status,21,39)
	fishing_track=Control.new()
	fishing_track.size=Vector2(606,50)
	fishing_track.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fishing_track.draw.connect(draw_fishing)
	place(card,fishing_track,21,61)
	fishing_button=btn("Reel in",reel)
	fishing_button.focus_mode=Control.FOCUS_NONE
	farm_hud.list_button(self,fishing_button)
	place(card,fishing_button,21,108)
	fishing_button.custom_minimum_size=Vector2(204,39)
	place(fishing_button,keycap(Controls.name_for(model,"Work / reel")),135,7)
	var tip:=lbl("Reel at the splash." if practice_cast else "Reel inside the brackets.",16,Color("#dec7a1"))
	place(card,tip,229,116)
	var back:=btn("Cancel",close_page)
	farm_hud.list_button(self,back)
	place(card,back,492,108)
	back.focus_mode=Control.FOCUS_NONE
	back.custom_minimum_size=Vector2(133,35)
	place(back,keycap("Esc"),86,6)
	refresh_fishing_panel()

func float_position()->float:
	if practice_cast and fishing_time>=bite_at and fishing_time<bite_at+1.6:return .61
	return .5+.45*sin(maxf(0,fishing_time-bite_at)*float(fishing_spec.speed)*2.2-.8)

func catch_width()->float:
	var assist:=.205 if int(model.s.fishing_xp)<3 else .142
	if model.s.tools.get("rod-upgrade",false):assist+=.04
	if baited:assist+=.025
	if tonic_cast:assist+=.065
	return assist+minf(.025,float(model.s.fishing_xp)*.00045)

func refresh_fishing_panel():
	var hooked:=fishing_time>=bite_at
	var ready:=hooked and absf(float_position()-.61)<=catch_width()
	fishing_status.text=("Reel now!" if ready else "Bite! Watch the float.") if hooked else ("Casting…" if fishing_time<.52 else "Wait for a bite…")
	fishing_status.add_theme_color_override("font_color",Color("#d7f6b8") if ready else IVORY)
	fishing_button.disabled=not hooked
	fishing_button.modulate=Color("#e4ffcb") if ready else Color.WHITE
	fishing_track.queue_redraw()

func draw_fishing():
	var w:=fishing_track.size.x
	var lane:=Rect2(2,5,w-4,42)
	fishing_track.draw_rect(lane,Color("#1b302c"))
	fishing_track.draw_rect(lane,Color("#ad9569"),false,1)
	if fishing_time<bite_at:
		var at:=Vector2(w*.5,27+sin(fishing_time*7)*2)
		draw_fishing_float(at)
		return
	var band:=Rect2(w*(.61-catch_width()),6,w*2*catch_width(),40)
	var x:=clampf(float_position()*w,10,w-10)
	var ready:=band.has_point(Vector2(x,27))
	fishing_track.draw_rect(band,Color("#659657") if ready else Color("#395e3b"))
	fishing_track.draw_rect(band,Color("#c1df9e"),false,2)
	for edge:float in [band.position.x,band.end.x]:
		fishing_track.draw_line(Vector2(edge,9),Vector2(edge,42),Color.WHITE,2)
	if ready:fishing_track.draw_colored_polygon(PackedVector2Array([Vector2(x-4,3),Vector2(x+4,3),Vector2(x,8)]),Color.WHITE)
	draw_fishing_float(Vector2(x,27))

func draw_fishing_float(at:Vector2):
	if world.tex.has("cast-bobber"):
		fishing_track.draw_texture_rect(world.tex["cast-bobber"],Rect2(at-Vector2(12,15),Vector2(24,30)),false)
	else:fishing_track.draw_circle(at,8,Color("#f3d699"))

func reel():
	if page!="Creek fishing" or fishing_time<bite_at:
		return
	var target:=absf(float_position()-.61)
	var fish:=fishing_spec
	var on_target:=target<=catch_width()
	var caught:=on_target and model.change(fish.id,1)
	close_page()
	world.fishing.resolve(caught)
	world.fishing.update(world,0.0,false)
	if not caught:
		var phase_angle:=maxf(0,fishing_time-bite_at)*float(fish.speed)*2.2-.8
		var early:bool=(float_position()-.61)*cos(phase_angle)<0
		feedback("Make room in your satchel." if on_target else (("A little early." if early else "A little late.")+" Press E at the lantern to cast again."))
		return
	var good:=target<catch_width()*.4
	var length:=randi_range(18,38)+(14 if good else 0)
	var record:Dictionary=model.s.fish_records.get(fish.id,{})
	model.s.fish_records[fish.id]={"best_cm":maxi(length,int(record.get("best_cm",0))),"fine":int(record.get("fine",0))+(1 if good else 0)}
	model.s.catches[fish.id]=int(model.s.catches.get(fish.id,0))+1
	Expansion.record(model,fish.id,Routes.NAMES[world.area])
	if fishing_site=="river" and model.weather(model.s.day)=="Showers":model.s.mine.rain_catch=true
	model.s.fishing_xp+=3 if good else 1
	store()
	var first:=record.is_empty()
	var best:=not first and length>int(record.get("best_cm",0))
	feedback("%s%s  ·  %d cm"%["First catch!  " if first else ("New record!  " if best else ""),fish.name,length],first or best)
	if first or best:
		for previous in hud.get_children():
			if previous.has_meta("catch_badge"):previous.queue_free()
		var badge:=TextureRect.new()
		badge.set_meta("catch_badge",true)
		badge.texture=world.tex["catch-"+fish.id]
		badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.size=Vector2(65,43)
		badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		place(hud,badge,23,149)
		var reveal:=badge.create_tween()
		reveal.tween_interval(2)
		reveal.tween_property(badge,"modulate:a",0,.4)
		reveal.tween_callback(badge.queue_free)
func _exit_tree():
	if is_instance_valid(world.foot_player):world.foot_player.stop()
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	music.stop()
	ambiance.stop()
	fx.stop()
func quit_game():
	if closing:return
	closing=true
	if active:store()
	active=false
	music.stop()
	ambiance.stop()
	fx.stop()
	# Let the audio mixer release queued playback before the tree comes down.
	await get_tree().create_timer(.18).timeout
	get_tree().quit()

func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST:quit_game()


func buy_supply(id:String,cost:int,destination:String):
	if model.s.coins<cost:
		var hint:="You need %d more crowns. The shipping bin pays each morning."%(cost-int(model.s.coins))
		if is_instance_valid(purchase_status) and destination=="Mercantile counter":purchase_status.text=hint
		else:note(hint)
		return
	if Life.TOOLS.has(id) or id=="mine-lantern":
		if model.s.tools.get(id,false):return
		model.s.tools[id]=true
	elif not model.change(id,1):
		note("Make room in your satchel first.")
		return
	model.s.coins-=cost
	store()
	show_page(destination)
	var message:="%s equipped."%Life.TOOLS[id][0] if Life.TOOLS.has(id) else "%s purchased."%model.item_name(id)
	if id=="axe":message=axe_route()
	if destination=="Mercantile counter":
		purchase_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		purchase_status.text=message
	else:note(message)

func axe_route()->String:
	return "Axe equipped. Take the north trail from Willowbrook to Alderwood Grove. Chop an alder with E three times. Four wood makes a garden bench in Workshop (C)."

func show_market_customer(buyer:String,item:String,price:int):
	close_page()
	page="Market customer"
	world.update_target()
	var sprite:Sprite2D=world.npcs[buyer]
	world.occupation(sprite,buyer,false)
	sprite.texture=world.resident_heads[buyer]
	sprite.hframes=8
	sprite.vframes=4
	sprite.offset=Vector2(0,-21)
	sprite.rotation=0
	sprite.show()
	var stop:=Vector2(951,484)
	var start:Vector2=sprite.position if sprite.position.distance_to(stop)<120 else stop+Vector2(-52,8)
	var anim:=create_tween()
	anim.tween_method(func(t:float):
		sprite.position=start.lerp(stop,t).round()
		sprite.frame=8+int(t*16)%6,0.0,1.0,.85)
	anim.tween_callback(func():
		sprite.frame=22
		feedback("%s inspects your %s and pays %d crowns."%[buyer,model.item_name(item),price]))
	anim.tween_interval(1.1)
	anim.tween_method(func(t:float):
		sprite.position=stop.lerp(start,t).round()
		sprite.frame=24+int(t*16)%6,0.0,1.0,.85)
	anim.tween_callback(func():
		world.refresh_people()
		if page=="Market customer":show_page("Player market stall"))

func arcade_icon(id:String)->Texture2D:
	match id:
		"rod-upgrade":return world.tex["item-rod"]
		"sprinkler","broad-hoe":return world.tex[id]
		"long-can":return world.tex.can
		"home-lamp":return world.tex.bedside
		"home-cabinet":return world.tex["china-cupboard"]
		"home-wall":return world.tex["wallpaper-roll"]
		"home-rug":return world.tex["rag-rug"]
		"home-seat":return world.tex["planter-seat"]
		"garden-pot":return world.tex["garden-pot"]
		"compost":return world.tex.branch
	return farm_hud.product_icon(self,id)

func open_department(title:String):
	close_page()
	interact("shop:"+title)

func open_arcade_counter(id:String):
	if (world.area!="Arcade" and world.area!="Shop:"+id) or not Stock.STORES.has(id):return
	if not Stock.is_open(model):
		feedback("Arcade counters are open 09:00–19:00.")
		return
	arcade_shop=id
	arcade_feedback=""
	show_page("Arcade counter")

func select_arcade_item(index:int):
	arcade_item=index
	show_page("Purchase")

func inspect_tool(key:String):
	purchase_tool=key
	show_page("Tool preview")

func draw_equipment_preview(key:String,cost:int):
	var box:=Control.new()
	box.custom_minimum_size=Vector2(130,100)
	modal_box.add_child(box)
	var pose:=Sprite2D.new()
	pose.texture=world.work_farmer
	pose.hframes=4
	pose.vframes=4
	pose.frame=1
	pose.scale=Vector2.ONE*2
	pose.position=Vector2(70,48)
	box.add_child(pose)
	var tool:=Sprite2D.new()
	tool.texture=arcade_icon(key)
	tool.position=Vector2(88,58)
	tool.scale=Vector2.ONE*.8
	box.add_child(tool)
	note({"axe":"Chops alder and pine in Alderwood Grove.","pickaxe":"Breaks fieldstone and ore deposits.","rod-upgrade":"Widens the reeling window."}[key])
	note("Price %d · Wallet %d · %s"%[cost,model.s.coins,("%d crowns after purchase"%(model.s.coins-cost)) if model.s.coins>=cost else ("%d more crowns needed"%(cost-model.s.coins))])

func build_purchase_view():
	var item:Array=Stock.catalog_for(model,arcade_shop)[arcade_item]
	var supply:=Stock.stock(model,item)
	var header:=HBoxContainer.new()
	modal_box.add_child(header)
	header.add_theme_constant_override("separation",14)
	var icon:=TextureRect.new()
	icon.texture=arcade_icon(item[0])
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size=Vector2(62,59)
	header.add_child(icon)
	var title:=lbl(item[1],30,IVORY,true)
	header.add_child(title)
	note(item[5])
	if item[0] in ["axe","pickaxe","rod-upgrade"]:draw_equipment_preview(item[0],int(item[3]))
	note("%d crowns per %s  ·  %d crowns held  ·  %d in stock"%[item[3],"bundle of "+str(item[2]) if item[2]>1 else "item",model.s.coins,supply])
	purchase_status=lbl("",17,Color("#debd88"))
	modal_box.add_child(purchase_status)
	if int(model.s.coins)<int(item[3]) and supply>0:purchase_status.text="You need %d more crowns. Shipping pays at dawn."%(int(item[3])-int(model.s.coins))
	if supply>0:
		var balance:=lbl("After purchase · %d crowns"%maxi(0,int(model.s.coins)-int(item[3])),16,IVORY)
		if model.s.coins>=item[3]:modal_box.add_child(balance)
		else:balance.free()
		var quantity:=SpinBox.new()
		quantity.min_value=1
		quantity.max_value=maxi(1,mini(supply,int(model.s.coins)/int(item[3])))
		quantity.editable=supply>1
		quantity.visible=supply>1
		quantity.step=1
		quantity.value=1
		quantity.prefix="Quantity   "
		quantity.custom_minimum_size.y=48
		modal_box.add_child(quantity)
		var confirm:=btn("Buy for %d crowns"%item[3],finish_arcade_purchase.bind(quantity))
		farm_hud.list_button(self,confirm)
		confirm.disabled=int(model.s.coins)<int(item[3])
		modal_box.add_child(confirm)
		quantity.value_changed.connect(func(n:float):
			var total:=int(n)*int(item[3])
			confirm.text="Buy for %d crowns"%total
			if is_instance_valid(balance):balance.text="After purchase · %d crowns"%(model.s.coins-total))
	if Stock.FURNISHINGS.has(item[0]):row("Preview in the cottage",show_page.bind("Cottage preview"))
	row("Back to "+arcade_shop,show_page.bind("Arcade counter"))

func finish_arcade_purchase(quantity:SpinBox):
	var item:Array=Stock.catalog_for(model,arcade_shop)[arcade_item]
	var result:=Stock.purchase(model,arcade_shop,arcade_item,int(quantity.value))
	if result!="":
		if is_instance_valid(purchase_status):purchase_status.text=result
		return
	arcade_feedback="%s equipped."%item[1] if item[6] else "%s purchased."%item[1]
	var first_handoff:bool=result=="" and not model.s.expansion.projects.has("first-purchase-"+arcade_shop)
	if result=="":
		if first_handoff:
			model.s.expansion.projects["first-purchase-"+arcade_shop]=true
			var stall:Dictionary=Stock.STORES[arcade_shop]
			arcade_feedback="%s takes a fresh %s from the shelf and sets it on the counter."%[stall.keeper,str(item[1]).to_lower()]
		store()
	if item[0]=="axe":arcade_feedback=axe_route()
	if item[0]=="sprinkler":arcade_feedback="Field sprinkler installed. All prepared beds are watered."
	show_page("Arcade counter")
	if first_handoff:
		var parcel:=TextureRect.new()
		parcel.texture=arcade_icon(item[0])
		parcel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		parcel.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		parcel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		parcel.position=Vector2(889,141)
		parcel.size=Vector2(48,48)
		overlay.add_child(parcel)
		var handoff:=parcel.create_tween().set_parallel()
		handoff.tween_property(parcel,"position",Vector2(827,165),.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		handoff.tween_property(parcel,"modulate:a",0.0,.18).set_delay(.72)
		handoff.chain().tween_callback(parcel.queue_free)

func apply_arcade_item(id:String):
	if id!="compost" and world.area!="Cottage":
		note("Go home to install this furnishing.")
		return
	if Stock.FURNISHINGS.has(id) and model.s.furnishings.get(id,false):
		note("That furnishing is already installed.")
		return
	if not model.change(id,-1):return
	if id=="compost":model.s.compost_charges+=6
	else:
		model.s.furnishings[id]=true
		world.enter(world.area,world.pos)
	store()
	close_page()
	feedback("Applied "+model.item_name(id)+".")

func go_mine(depth:int):
	model.s.mine.depth=depth
	beetle_hits=0
	close_page()
	relocate("Mine",Mine.ENTRY,Vector2.UP)

func reopen_lift():
	if Mine.open_lift(model):
		store()
		show_page("Mine lift")
		note("Lift landing reopened.")

func ride_lift(depth:int):
	if depth<=int(model.s.mine.lift):go_mine(depth)

func forge(id:String):
	var result:=Mine.craft(model,id)
	if result!="":
		note(result)
		return
	store()
	show_page("Ves’s furnace")
	note("Ready: "+(model.item_name(id) if id!="sprinkler" else "Field sprinkler"))

func fuel_lantern():
	if world.area!="Mine" or not model.s.tools.get("mine-lantern",false):return
	if not model.change("coal",-1):return
	model.s.mine.fuel_until=maxf(Mine.clock(model),float(model.s.mine.fuel_until))+120.0
	store()
	close_page()
	feedback("Your lantern casts a wider pool of light.")

func eat_in_mine(item:String):
	if world.area!="Mine" or not Mine.FOOD.has(item) or float(model.s.mine.energy)>=100:return
	if not model.change(item,-1):return
	model.s.mine.energy=minf(100,float(model.s.mine.energy)+float(Mine.FOOD[item]))
	store()
	close_page()
	feedback("You recover some energy.")

func evacuate_mine():
	var fee:=mini(model.s.coins,12)
	model.s.coins-=fee
	model.s.mine.energy=50.0
	model.s.mine.fuel_until=-1.0
	close_page()
	relocate("Cottage",Vector2(420,366),Vector2.DOWN)
	feedback("Oren helped you home. Supplies cost %d crowns."%fee)

func fight_beetle():
	if world.area!="Mine" or not is_instance_valid(world.mine_beetle):return
	if world.impact_left>.12:return
	beetle_hits+=2 if model.s.tools.get("tempered-pick",false) else 1
	model.s.mine.energy=maxf(0,float(model.s.mine.energy)-4)
	var at:Vector2=world.mine_beetle.position
	if beetle_hits>=3:
		model.s.mine.beaten[str(model.s.mine.depth)]=true
		model.change("coal",1)
		world.enter("Mine",world.pos)
		beetle_hits=0
	world.mine_strike(at)
	store()
	if Mine.exhausted(model):evacuate_mine()

func seasonal_entry():
	var response:=SeasonEvents.reward(model)
	if response!="":note(response)
	else:
		store()
		close_page()
		feedback("You contributed to the seasonal market and received 24 crowns and three seeds.")

func build_cottage_preview():
	var item:Array=Stock.catalog_for(model,arcade_shop)[arcade_item]
	var selected:String=item[0]
	note(item[1]+" in the Hearth Room")
	var canvas:=Control.new()
	canvas.custom_minimum_size=Vector2(500,325)
	modal_box.add_child(canvas)
	var background:TextureRect=farm_hud.stamp(canvas,world.tex["oak-room"],Vector2(21,0),Vector2(540,312))
	background.size=Vector2(540,312)
	background.stretch_mode=TextureRect.STRETCH_SCALE
	if selected=="home-wall":preview_piece(canvas,"sage-wall",Vector2(29,14),Vector2(523,45))
	for x in [54,165,315]:preview_piece(canvas,"window",Vector2(x,13),Vector2(54,62))
	preview_piece(canvas,"bed",Vector2(89,43),Vector2(72,103))
	preview_piece(canvas,"range",Vector2(375,30),Vector2(75,95))
	preview_piece(canvas,"tea-table",Vector2(123,132),Vector2(94,87))
	var rug:="rag-rug" if selected=="home-rug" or model.s.furnishings.get("home-rug",false) else "blue-rug"
	preview_piece(canvas,rug,Vector2(372,204),Vector2(118,63))
	if selected=="home-seat":preview_piece(canvas,"planter-seat",Vector2(59,235),Vector2(68,44))
	if selected=="home-lamp":preview_piece(canvas,"bedside",Vector2(355,238),Vector2(38,48))
	if selected=="home-cabinet":preview_piece(canvas,"china-cupboard",Vector2(335,76),Vector2(47,76))
	row("Back to purchase",show_page.bind("Purchase"))

func preview_piece(parent:Control,art:String,at:Vector2,size_:Vector2):
	var piece:TextureRect=farm_hud.stamp(parent,world.tex[art],at,size_)
	piece.size=size_



