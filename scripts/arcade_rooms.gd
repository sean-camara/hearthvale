extends RefCounted

const Stock=preload("res://scripts/arcade_stock.gd")
const FONT=preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const FLOOR_WALKS:={
	"Arcade":[Rect2(296,263,560,250),Rect2(530,495,92,28)],
	"RiverLodge":[Rect2(325,286,242,167),Rect2(566,313,221,142),Rect2(528,430,114,93)],
	"Herbarium":[Rect2(317,282,253,168),Rect2(569,300,245,169),Rect2(537,441,117,82)],
	"CraftsHouse":[Rect2(318,270,482,100),Rect2(333,370,230,119),Rect2(562,370,220,114),Rect2(531,470,112,53)],
	"SeedLoft":[Rect2(345,286,192,191),Rect2(535,341,223,128),Rect2(521,452,109,71)],
	"BakerLoft":[Rect2(345,285,442,158),Rect2(487,440,191,83)],
}
const INTERIOR_WALLS:={
	"RiverLodge":[Rect2(560,288,8,65),Rect2(560,407,8,37)],
	"Herbarium":[Rect2(563,281,9,58),Rect2(563,392,9,48)],
	"CraftsHouse":[Rect2(316,363,134,8),Rect2(508,363,101,8),Rect2(677,363,123,8)],
	"SeedLoft":[Rect2(531,286,9,81),Rect2(531,418,9,48)],
	"BakerLoft":[Rect2(662,286,9,59),Rect2(662,386,9,56)],
}
const OWNERS:={"RiverLodge":"Oren","Herbarium":"Linn and Nell","CraftsHouse":"Mara, Ves, and Tavi","SeedLoft":"Iona","BakerLoft":"Pip"}
const BEDS:={"Oren":Vector2(403,328),"Linn":Vector2(409,337),"Nell":Vector2(746,351),"Mara":Vector2(382,319),"Ves":Vector2(518,318),"Tavi":Vector2(746,315),"Iona":Vector2(408,331),"Pip":Vector2(741,341)}
const HOMES={
	"RiverLodge":{
		"windows":[[384,257],[651,289],[746,289]],"rug":["blue-rug",660,377,.85],
		"props":[["bed",403,318,.76,56,25],["bedside",456,312,.66,31,16],["tea-table",663,374,.78,71,26],
			["pantry",740,326,.79,48,21],["hearth-logs",370,415,.68,31,18],["settle",714,432,.68,75,22],
			["item-rod",357,344,1.15,12,9],["pots",755,416,.66,22,13]],"ledger":Vector2(621,430)},
	"Herbarium":{
		"windows":[[376,253],[492,253],[726,278]],"rug":["rag-rug",670,427,.78],
		"props":[["bed",409,327,.78,57,28],["bed",746,340,.77,56,27],["herb-table",495,328,.88,76,29],
			["bookcase",652,333,.72,54,18],["potted-leaves",369,401,1.13,28,18],
			["potted-leaves",779,418,.95,21,17],["tea-table",688,430,.68,65,25],["garden-pot",487,420,.83,28,18]],"ledger":Vector2(497,344)},
	"CraftsHouse":{
		"windows":[[382,241],[528,241],[745,241]],"rug":["blue-rug",660,430,.85],
		"props":[["bed",382,309,.68,54,24],["bed",518,309,.68,54,24],["bed",746,305,.68,54,24],
			["general-counter",417,426,.83,103,34],["spinning-wheel",535,434,.80,45,25],
			["hearth-logs",359,461,.75,40,16],["range",756,433,.66,57,24],
			["china-cupboard",773,468,.62,41,18]],"ledger":Vector2(417,446)},
	"SeedLoft":{
		"windows":[[395,257],[475,257],[685,319]],"rug":["rag-rug",674,413,.8],
		"props":[["bed",408,321,.84,59,34],["herb-table",661,378,.79,71,24],["bookcase",468,335,.65,45,24],
			["bedside",379,383,.73,26,20],["pots",728,444,1,29,20],["settle",684,456,.66,71,20]],"ledger":Vector2(661,394)},
	"BakerLoft":{
		"windows":[[412,256],[585,256],[739,256]],"rug":["blue-rug",594,460,.85],
		"props":[["bed",741,330,.79,56,27],["range",417,324,.86,72,30],["pantry",544,308,.95,46,20],
			["tea-table",542,395,.86,85,37],["pastry-counter",401,420,.60,65,25],
			["bedside",704,392,.72,31,19]],"ledger":Vector2(544,416)},
}

static func walkable(area:String,at:Vector2)->bool:
	for rect:Rect2 in FLOOR_WALKS.get(area,[]):
		if rect.has_point(at):return true
	return false

static func place_sign(world,at:Vector2,title:String,arrow:String="",hanging:=false):
	var art:="sign-hanging" if hanging else "sign-route"
	var board:=Sprite2D.new()
	board.texture=world.tex[art]
	board.position=at
	board.scale=Vector2.ONE*(.76 if hanging else .79)
	if hanging:
		board.z_index=1
		world.low_detail.add_child(board)
	else:
		board.position.y+=22
		board.offset.y=-22 / board.scale.y
		world.actors.add_child(board)
	var plaque:=Rect2(-62,4,110,19) if hanging else Rect2(-62,-7-22/board.scale.y,121,19)
	var icon_side:=16 if not hanging else 0
	if icon_side>0:
		var emblem:=Sprite2D.new()
		emblem.texture=world.Details.art(world.Details.emblem(title))
		emblem.position=Vector2(plaque.position.x+8,plaque.get_center().y)
		emblem.scale=Vector2.ONE*(13.0/maxf(emblem.texture.get_width(),emblem.texture.get_height()))
		board.add_child(emblem)
	var arrow_side:=15 if arrow!="" else 0
	var arrow_first:=arrow in ["←","↑"]
	if arrow!="":
		var at_x:=plaque.position.x+icon_side if arrow_first else plaque.end.x-arrow_side
		board.add_child(sign_label(arrow,Rect2(at_x,plaque.position.y,arrow_side,plaque.size.y),13))
	var label_x:=plaque.position.x+icon_side+(arrow_side if arrow_first else 0)
	var label_width:=plaque.size.x-icon_side-arrow_side
	board.add_child(sign_label(title,Rect2(label_x,plaque.position.y,label_width,plaque.size.y),12))

static func sign_label(title:String,bounds:Rect2,preferred:int)->Label:
	var label:=Label.new()
	label.text=title
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",FONT)
	var font_size:=preferred
	while font_size>8 and FONT.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>bounds.size.x-3:font_size-=1
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#fff0c1"))
	label.add_theme_color_override("font_outline_color",Color("#22180f"))
	label.add_theme_constant_override("outline_size",2)
	label.clip_text=true
	label.position=bounds.position
	label.size=bounds.size
	return label

static func home(world,area:String):
	world.ground_detail("layout-"+area.to_lower(),Vector2(576,356),1)
	for wall in INTERIOR_WALLS.get(area,[]):world.barriers.append(wall)
	var plan:Dictionary=HOMES[area]
	for item in plan.windows:world.ground_detail("window",Vector2(item[0],item[1]),.71)
	var rug:Array=plan.rug
	world.ground_detail(rug[0],Vector2(rug[1],rug[2]),rug[3])
	world.ground_detail("threshold",Vector2(577,513),.83)
	for prop_:Array in plan.props:
		world.spot_furniture(prop_[0],Vector2(prop_[1],prop_[2]),prop_[3],Vector2(prop_[4],prop_[5]))
	world.targets["Leave home"]=Vector2(577,510)
	world.targets["Household ledger"]=plan.ledger

static func mall(world):
	world.ground_detail("layout-arcade",Vector2(576,356),1)
	for x in [355,576,797]:world.ground_detail("window",Vector2(x,237),.74)
	for title:String in Stock.STORES:
		var store:Dictionary=Stock.STORES[title]
		var anchor:Vector2=store.at
		world.ground_detail("rag-rug" if anchor.y<400 else "blue-rug",anchor+Vector2(0,44),.72)
		world.spot_furniture(store.art,anchor,.62,Vector2(83,22))
		world.targets["counter:"+title]=anchor+Vector2(0,12)
		world.targets["shop:"+title]=anchor+Vector2(-55,14)
		world.ground_detail("threshold",anchor+Vector2(-50,21),.36)
		var crest:String={"Farm Supply":"crest-wheat","Tackle Shop":"crest-trout","Flowers & Garden":"crest-flower"}.get(title,"")
		if crest!="":world.ground_detail(crest,anchor+Vector2(-51,-22),.64)
		place_sign(world,anchor+Vector2(0,-62),title,"",true)
	for deco in [["potted-leaves",310,339,.63],["bookcase",833,282,.55],["garden-pot",822,341,.64],["china-cupboard",641,441,.57],["pantry",820,432,.58]]:
		world.prop(deco[0],Vector2(deco[1],deco[2]),deco[3])
	if world.model.season()>=6:
		world.prop("dock-lantern",Vector2(449,500),.7)
		world.prop("dock-lantern",Vector2(701,500),.7)
	else:
		world.prop("garden-pot",Vector2(443,501),.72)
		world.prop("garden-pot",Vector2(708,501),.72)
	world.targets["Arcade directory"]=Vector2(490,494)
	place_sign(world,Vector2(490,478),"Directory")
	world.targets["Leave arcade"]=Vector2(577,510)
	world.ground_detail("threshold",Vector2(577,514),1)


static func shop(world,title:String):
	var store:Dictionary=Stock.STORES[title]
	var decorations:Dictionary={
		"Farm Supply":[["bin",380,340],["chest",767,340],["basket",414,398],["spinning-wheel",737,426]],
		"Tackle Shop":[["item-rod",386,322],["chest",771,340],["pier",749,412],["dock-lantern",406,391]],
		"Flowers & Garden":[["potted-leaves",390,332],["garden-pot",758,347],["glasshouse",742,424],["flowers",401,391]],
		"Tool & Hardware":[["mine-furnace",389,346],["hearth-logs",760,340],["item-pickaxe",740,424],["pots",420,425]],
		"Furniture & Home":[["china-cupboard",389,342],["settle",751,437],["bedside",746,331],["spinning-wheel",425,419]],
		"General Goods":[["pantry",395,334],["well",749,334],["pots",727,405],["basket",424,388]],
	}
	world.ground_detail("oak-room",Vector2(576,356),1.0)
	if world.tex.has("shop"):world.ground_detail("shop",Vector2(576,398),1)
	world.ground_detail("window",Vector2(474,237),.84)
	world.ground_detail("window",Vector2(665,237),.84)
	var rug:="blue-rug" if title in ["Tackle Shop","Tool & Hardware","Furniture & Home"] else "rag-rug"
	world.ground_detail(rug,Vector2(576,429),1.07)
	world.ground_detail("threshold",Vector2(576,514),.92)
	for decor:Array in decorations[title]:
		if not world.tex.has(decor[0]):continue
		world.spot_furniture(decor[0],Vector2(decor[1],decor[2]),.83,Vector2(25,16))
	var counter:=Vector2(572,361)
	world.spot("counter:"+title,store.art,counter,.94,Vector2(96,24))
	var keeper:Sprite2D=world.prop(store.keeper.to_lower(),Vector2(590,317),1)
	world.counter_keeper=keeper
	keeper.hframes=3
	keeper.offset=Vector2(0,-18)
	world.targets["Leave department"]=Vector2(577,510)
	world.targets[store.keeper]=Vector2(594,347)
	place_sign(world,Vector2(570,254),title,"",true)
