extends RefCounted
# Build nine-slice game controls from the same painted wood and parchment masters.
const ART="res://assets/spring/"
const PAPER=Color("#fbe6b5")
const INK=Color("#432e23")
const TOOL_ICONS=["hoe","packet","can","basket"]
var textures:Dictionary={}
var icons:Array[TextureRect]=[]
var counts:Array[Label]=[]
var stacks:Array[String]=[]
var slots:Array[Button]=[]
var plates:Dictionary={}
var latest:=""
var prompt_plate:Panel
var prompt_key:Label

func _init():
	for id in ["wood","slot","selected","leaf","hoe","packet","can","basket","satchel","branch","hen","produce","jar"]:
		textures[id]=load(ART+id+".png")
	for id in ["wood","slot","selected"]:
		var plate:=StyleBoxTexture.new()
		plate.texture=textures[id]
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			var margin:=8 if id!="wood" else (22 if side in [SIDE_LEFT,SIDE_RIGHT] else 18)
			plate.set_texture_margin(side,margin)
			plate.set_content_margin(side,12 if id=="wood" else 8)
		plate.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		plate.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		plates[id]=plate

func paper_button(button:Button):
	for state in ["normal","hover","pressed","focus"]:
		button.add_theme_stylebox_override(state,plates.slot if state=="normal" else plates.selected)
	for label in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		button.add_theme_color_override(label,INK)
	button.custom_minimum_size.y=44

func list_button(game,button:Button):
	var inks:Dictionary={
		"normal":Color("#ecd2a4"),"hover":Color("#f6dfb6"),"pressed":Color("#d5ad74"),
	}
	for state:String in inks:
		var edge:=Color("#b38553") if state=="normal" else Color("#f8dda4")
		var paper:StyleBoxFlat=game.style(inks[state],edge,16)
		paper.border_width_bottom=3
		button.add_theme_stylebox_override(state,paper)
	var focus:=StyleBoxFlat.new()
	focus.draw_center=false
	focus.border_color=Color("#fff1bd")
	focus.set_corner_radius_all(5)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus",focus)
	for label in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		button.add_theme_color_override(label,INK)
	button.custom_minimum_size.y=44
	button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS

func stamp(parent:Control,texture:Texture2D,at:Vector2,dimensions:Vector2)->TextureRect:
	var rect:=TextureRect.new()
	rect.texture=texture
	rect.position=at
	rect.size=dimensions
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func plaque(game,parent:Control,at:Vector2,dimensions:Vector2)->Panel:
	var p:Panel=game.panel(parent,at,dimensions)
	p.add_theme_stylebox_override("panel",plates.wood)
	return p

func build(game):
	var top:=plaque(game,game.hud,Vector2(16,15),Vector2(407,85))
	stamp(top,textures.leaf,Vector2(15,8),Vector2(34,34))
	game.area_label=game.lbl("",27,PAPER,true)
	game.place(top,game.area_label,53,6)
	game.clock_label=game.lbl("",16,PAPER)
	game.place(top,game.clock_label,19,47)
	var journal:Button=game.btn("Journal",game.show_page.bind("Journal"))
	journal.custom_minimum_size=Vector2(138,51)
	journal.alignment=HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal","hover","pressed","focus"]:journal.add_theme_stylebox_override(state,plates.wood)
	game.place(game.hud,journal,1124,16)
	game.place(journal,game.keycap("J"),100,12)
	var bar:=plaque(game,game.hud,Vector2(309,628),Vector2(662,82))
	for i in range(9):
		var b:=Button.new()
		b.focus_mode=Control.FOCUS_NONE
		b.size=Vector2(66,61)
		b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("normal",plates.slot)
		b.add_theme_stylebox_override("hover",plates.selected)
		b.add_theme_stylebox_override("pressed",plates.selected)
		game.place(bar,b,15+i*70,10)
		var icon:=stamp(b,textures[TOOL_ICONS[i]] if i<4 else null,Vector2(10,8),Vector2(47,43))
		var key:Label=game.lbl(str(i+1),15,INK)
		key.add_theme_color_override("font_outline_color",Color("#f9e0ab"))
		key.add_theme_constant_override("outline_size",3)
		game.place(b,key,7,3)
		var count:Label=game.lbl("",16,INK)
		count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		count.size=Vector2(55,20)
		game.place(b,count,4,36)
		slots.append(b)
		icons.append(icon)
		counts.append(count)
		if i<4:
			b.tooltip_text=game.TOOLS[i]+"  ("+str(i+1)+")"
			b.pressed.connect(game.select_tool.bind(i))
		else:b.pressed.connect(quick_action.bind(game,i))
	prompt_plate=plaque(game,game.hud,Vector2(16,646),Vector2(220,45))
	prompt_plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	prompt_key=game.keycap("E")
	game.place(prompt_plate,prompt_key,13,9)
	game.context=game.lbl("",17,PAPER)
	game.place(prompt_plate,game.context,49,11)
	game.toast=game.lbl("",17,INK)
	game.toast.add_theme_stylebox_override("normal",plates.slot)
	game.place(game.hud,game.toast,19,108)
	game.toast.hide()

func update_context(game):
	var hover:String=game.world.hover_target
	var nearby:bool=game.world.near!="" or hover!=""
	var distant:bool=game.world.beyond!=""
	var target:String=game.world.beyond if distant else (hover if hover!="" else game.world.near)
	prompt_key.text=game.Controls.name_for(game.model,"Interact" if nearby else ("Work / reel" if game.world.area=="Farm" else "Map"))
	if hover!="":prompt_key.text="Click"
	game.context.text=game.world.node_label(target) if nearby else (game.TOOLS[game.world.tool] if game.world.area=="Farm" else "Valley map")
	if distant:game.context.text="Step closer · "+game.world.node_label(target)
	game.context.position.x=22+prompt_key.get_minimum_size().x
	prompt_plate.size.x=minf(280,game.context.position.x+game.context.get_minimum_size().x+17)

	if nearby or distant:
		var point:Vector2=game.world.get_global_transform_with_canvas()*Vector2(game.world.targets[target])
		prompt_plate.position=(point+Vector2(-prompt_plate.size.x*.5,16)).clamp(Vector2(10,117),Vector2(1270-prompt_plate.size.x,599))
	else:prompt_plate.position=Vector2(16,646)

func quick_action(game,i:int):
	if i<4 or i-4>=stacks.size():return
	var id:=stacks[i-4]
	if id.begins_with("s") and id.substr(1).is_valid_int():
		game.model.s.seed=int(id.substr(1));game.select_tool(1)
	elif game.model.workshop.has(id) and game.world.area=="Farm":game.place_decor(id)
	else:game.show_page("Satchel")

func product_icon(game,id:String)->Texture2D:
	var life_icon:String=game.HomesteadLife.Icons.get(id,"")
	if life_icon!="":return game.world.tex[life_icon]
	var orchard_art:String={"orchard-apple":"project-apple","orchard-pear":"project-pear","orchard-jar":"project-preserves"}.get(id,"")
	if orchard_art!="":return game.world.tex[orchard_art]
	if game.world.tex.has("catch-"+id):return game.world.tex["catch-"+id]
	if id.begins_with("s") and id.substr(1).is_valid_int():return textures.packet
	var region_art:String={"tide-shell":"shell","creek-pottery":"pottery","blossom-honey":"honey","herb-honey":"honey","creek-soup":"chowder","lake-whitefish":"fish","coast-bass":"fish","reedling":"fish","ice-darter":"fish","glassfin":"fish","highland-quartz":"quartz","ice-quartz":"quartz","frost-ray":"fish","woodland-cap":"forest-cap","frogmint":"mint","winter-sage":"mint","prairie-clover":"flowers","glassbloom":"flowers","moon-fruit":"orchard","river-glass":"crystals","lake-reed":"dunes"}.get(id,"")
	if game.world.tex.has(region_art):return game.world.tex[region_art]
	var asset:="res://assets/valley/item-"+id+".png"
	if ResourceLoader.exists(asset):return load(asset)
	var index:=-1
	if id.begins_with("p") and id.substr(1).is_valid_int():index=int(id.substr(1))
	elif id=="egg":index=12
	elif id=="herb":index=14
	elif game.model.village.foods.has(id):index=15
	if index>=0:
		var icon:=AtlasTexture.new()
		icon.atlas=textures.produce
		icon.region=Rect2(index%4*48,floori(index/4.0)*48,48,48)
		return icon
	if id.begins_with("jar"):return textures.jar
	if id=="wood":return textures.branch
	if id in ["stone","coal","iron-ore","iron-bar"]:return game.world.tex.rock
	if id=="moonstone":return game.world.tex["mine-crystal"]
	if id=="cave-char":return load("res://assets/valley/item-smelt.png")
	if id=="copper-bar":return game.world.tex["item-copper"]
	if id=="herb":return game.world.tex.mint
	if game.world.tex.has(id):return game.world.tex[id]
	return textures.basket

func update(game):
	var state_key:=str(game.world.tool)+"/"+str(game.model.s.seed)+"/"+str(game.model.s.bag)
	if latest==state_key:return
	latest=state_key
	stacks.clear()
	var ids:Array=game.model.s.bag.keys()
	ids.sort()
	# Show produce before seed stacks so a fresh harvest is visible immediately.
	for prefix in ["p","other"]:
		for id:String in ids:
			var produce:=id.begins_with("p") and id.substr(1).is_valid_int()
			if (prefix=="p")==produce and stacks.size()<5 and id!="s"+str(int(game.model.s.seed)):stacks.append(id)
	for i in range(9):
		slots[i].add_theme_stylebox_override("normal",plates.selected if i==game.world.tool else plates.slot)
		if i==1:counts[i].text=str(game.model.qty("s"+str(int(game.model.s.seed))))
		if i<4:continue
		var filled:=i-4<stacks.size()
		slots[i].mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if filled else Control.CURSOR_ARROW
		icons[i].texture=product_icon(game,stacks[i-4]) if filled else null
		counts[i].text=str(game.model.qty(stacks[i-4])) if filled else ""
		slots[i].tooltip_text=game.model.item_name(stacks[i-4]) if filled else ""

