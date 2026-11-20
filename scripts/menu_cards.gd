extends RefCounted

const CREAM:=Color("#f9e5bd")
const MUTED:=Color("#c8ae8d")
const GOLD:=Color("#efc077")

static func outline(game,node:Control)->void:
	for state in ["normal","hover","pressed","focus","disabled"]:
		var fill:Color={"normal":Color("#493229"),"hover":Color("#624835"),"pressed":Color("#75553a"),"focus":Color("#5c4332"),"disabled":Color("#3e3027")}[state]
		var border:=Color("#eac486") if state=="focus" else Color("#876448")
		node.add_theme_stylebox_override(state,game.style(fill,border,11))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		node.add_theme_color_override(state,CREAM)
	node.add_theme_color_override("font_disabled_color",MUTED)

static func product(game,title:String,price:int,status:String,action:Callable,icon:Texture2D):
	var button:Button=game.btn(title,action)
	outline(game,button)
	button.custom_minimum_size.y=55
	button.clip_text=true
	button.tooltip_text=title + (" · %d crowns"%price if price>=0 else "") + (" · "+status if status!="" else "")
	if icon!=null:
		button.icon=icon
		button.add_theme_constant_override("icon_max_width",35)
		button.add_theme_constant_override("h_separation",11)
	game.modal_box.add_child(button)
	var tag:=HBoxContainer.new()
	tag.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tag.alignment=BoxContainer.ALIGNMENT_END
	tag.add_theme_constant_override("separation",9)
	button.add_child(tag)
	tag.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	tag.offset_left=-158
	tag.offset_right=-12
	if status!="":tag.add_child(game.lbl(status,13,MUTED))
	if price>=0:tag.add_child(game.lbl("%d crowns"%price,15,GOLD))
	# Reserve the end of the row for price and stock, even with larger text.
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box:StyleBoxFlat=button.get_theme_stylebox(state)
		box.content_margin_right=170
	return button

static func header(game,title:String,subtitle:String,icon:Texture2D=null):
	var card:=PanelContainer.new()
	card.add_theme_stylebox_override("panel",game.style(Color("#392c24"),Color("#9b7452"),12))
	game.modal_box.add_child(card)
	var line:=HBoxContainer.new()
	line.add_theme_constant_override("separation",13)
	card.add_child(line)
	if icon!=null:add_icon(line,icon,Vector2(40,40))
	var labels:=VBoxContainer.new()
	labels.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	line.add_child(labels)
	var name_:Label=game.lbl(title,22,CREAM,true)
	name_.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(name_)
	var meta:Label=game.lbl(subtitle,15,MUTED)
	meta.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(meta)

static func add_icon(parent:Control,texture:Texture2D,size_:Vector2):
	var art:=TextureRect.new()
	art.custom_minimum_size=size_
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture=texture
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)

static func journal(game):
	var model=game.model
	header(game,model.s.farmer_name,"%s harvested  ·  %s shipped"%[model.s.harvests,model.s.sold],game.world.tex["packet"])
	var quest:=int(model.s.quest)
	var title:String=["Meet Iona","Iona’s first delivery","First delivery complete"][quest]
	var task:String=["Find Iona across the bridge in Willowbrook.","Bring one Breakfast radish to the seed stall · 30 crowns.","Check the village order book for more deliveries."][quest]
	header(game,title,task,game.farm_hud.product_icon(game,"p0"))
	var groups:=[
		[["Projects","Journal projects","mallet"],["Field notes","Journal field notes","sprig"],["People","Journal people","satchel"]],
		[["Orders","Village orders","seeds"],["Calendar","Calendar","lamp"],["Workshop","Workshop","pot"]],
	]
	for group in groups:
		var strip:=HBoxContainer.new()
		strip.add_theme_constant_override("separation",8)
		game.modal_box.add_child(strip)
		for item:Array in group:
			var card:Button=game.btn(item[0],game.show_page.bind(item[1]))
			outline(game,card)
			card.custom_minimum_size.y=49
			card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			card.alignment=HORIZONTAL_ALIGNMENT_CENTER
			card.icon=game.Details.art(item[2])
			card.add_theme_constant_override("icon_max_width",25)
			card.add_theme_constant_override("h_separation",7)
			strip.add_child(card)
	game.row("Market supper",game.show_page.bind(game.Projects.Market),game.world.tex["project-supper"])

static func satchel(game,filter:String):
	var model=game.model
	header(game,"%d stacks"%model.s.bag.size(),"%d crowns"%model.s.coins,game.farm_hud.textures.satchel)
	var filters:=HBoxContainer.new()
	filters.add_theme_constant_override("separation",7)
	game.modal_box.add_child(filters)
	for key in ["All","Seeds","Equipment"]:
		var tab:Button=game.btn(key,game.filter_satchel.bind(key))
		outline(game,tab)
		tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tab.toggle_mode=true
		tab.button_pressed=filter==key
		tab.alignment=HORIZONTAL_ALIGNMENT_CENTER
		filters.add_child(tab)
	var grid:=GridContainer.new()
	grid.columns=5
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	game.modal_box.add_child(grid)
	if filter=="Equipment":
		for key:String in ["axe","pickaxe","rod","rod-upgrade","tempered-pick","mine-lantern","sprinkler"]:
			if model.s.tools.get(key,false):inventory_tile(game,grid,key,0,true)
	else:
		for key:String in model.s.bag:
			if filter=="All" or (key.begins_with("s") and key.substr(1).is_valid_int()):
				inventory_tile(game,grid,key,int(model.qty(key)),false)
	if grid.get_child_count()==0:game.note("This pocket is empty.")

static func inventory_tile(game,grid:GridContainer,key:String,count:int,equipment:bool):
	var caption:String=game.model.item_name(key)
	if equipment:
		caption=str(game.Life.TOOLS.get(key,[caption])[0])
		if key=="sprinkler":caption="Field sprinkler"
	if key.begins_with("s") and key.substr(1).is_valid_int() and int(key.substr(1))==int(game.model.s.seed):
		caption+=" · Equipped"
	var tile:Button=game.btn("",game.inspect_satchel.bind(key,caption,count))
	outline(game,tile)
	tile.custom_minimum_size=Vector2(98,78)
	tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tile.tooltip_text=caption
	grid.add_child(tile)
	var face:=VBoxContainer.new()
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tile.add_child(face)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_KEEP_SIZE,6)
	face.add_theme_constant_override("separation",1)
	add_icon(face,game.arcade_icon(key),Vector2(36,31))
	var label:Label=game.lbl(caption,12,CREAM)
	label.custom_minimum_size.y=18
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	face.add_child(label)
	var qty:Label=game.lbl("×%d"%count if not equipment else "Equipped",13,GOLD)
	qty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	face.add_child(qty)

