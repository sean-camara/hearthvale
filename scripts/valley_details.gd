extends RefCounted

const PATH:="res://assets/seasons/"
const FLOORS:={"Cottage":0,"Bakery":1,"Shop:Tool & Hardware":2,"Mercantile":3,"Herbarium":4,"RiverLodge":5,"SeedLoft":6,"BakerLoft":7,"Arcade":8,"CraftsHouse":9,"Shop:Furniture & Home":10,"Shop:Flowers & Garden":11,"Shop:Tackle Shop":12,"Shop:General Goods":13,"Shop:Farm Supply":14}
const PROPS:={"Pip":"loaf","Linn":"sprig","Oren":"line","Mara":"mallet","Iona":"seeds","Ves":"pot","Tavi":"lamp","Nell":"kettle","Astra":"lamp","Kasim":"satchel","Briar":"sprig","Soren":"line"}
const EMBLEMS:={"Coast":"shell","Isles":"shell","Grove":"pine","Forest":"pine","Marsh":"sprig","Frost":"peak","Highlands":"peak","Mine":"cart","Below":"cart","IceCave":"peak","Desert":"wheel","Farm":"seeds","Village":"satchel","Plains":"seeds","Lakes":"line","Mercantile":"satchel","Bakery":"loaf","Arcade":"pot"}
const Routes=preload("res://scripts/world_routes.gd")

static func art(id:String)->Texture2D:
	return load(PATH+id+".png")

static func emblem(label:String)->String:
	for id:String in EMBLEMS:
		if label.contains(Routes.NAMES.get(id,id)) or label.contains(id):return EMBLEMS[id]
	for words in [["Alderwood","pine"],["Willowbrook","satchel"],["Hearthvale","seeds"],["Lighthouse","beacon"],["Pond","line"],["mine","cart"],["Mine","cart"],["ice cave","peak"],["Kettle","loaf"],["stall","seeds"]]:
		if label.contains(words[0]):return words[1]
	return "wreath"

static func floor_layer(w):
	if not FLOORS.has(w.area):return
	var tile:=Sprite2D.new()
	tile.texture=art("floor-"+str(FLOORS[w.area]))
	tile.texture_repeat=CanvasItem.TEXTURE_REPEAT_DISABLED
	tile.region_enabled=true
	tile.region_rect=Rect2(0,0,532,194)
	tile.position=Vector2(576,405)
	w.low_detail.add_child(tile)
	w.low_detail.move_child(tile,2 if w.area.begins_with("Shop:") and w.tex.has("shop") else 1)

static func route_hint(area:String,dest:String)->String:
	if area==dest:return "You’re here · "+Routes.NAMES[dest]
	if area=="Pasture":return "Follow the south trail back to Hearthvale."
	if area not in Routes.OUTDOORS:
		if area=="Below":return "Return through the galleries."
		return "Leave "+Routes.NAMES.get(area,area)+" to follow your pin."
	var goal:=Routes.map_region(dest)
	if dest=="Pasture":goal="Farm"
	if dest=="Below":goal="Grove"
	if dest=="Isles":goal="Coast"
	if area==goal:
		if dest=="Pasture":return "Use the gate southeast of the seedbeds."
		if dest=="Isles":return "Take the lighthouse ferry."
		if dest=="Below":return "Enter Alderwood Mine and descend to level 9."
		return "Enter "+Routes.NAMES.get(dest,dest)
	if area=="Isles":return "Take the return ferry to Sunshore."
	if area=="Below":return "Return through the mine galleries."
	var queue:Array=[[area,""]]
	var seen:={}
	seen[area]=true
	while not queue.is_empty():
		var here:Array=queue.pop_front()
		for side:String in Routes.links(here[0]):
			var neighbor:String=Routes.links(here[0])[side][0]
			if seen.has(neighbor):continue
			var first:String=side if here[1]=="" else here[1]
			if neighbor==goal:return "Take the "+first+" exit toward "+Routes.NAMES[Routes.links(area)[first][0]]+"."
			seen[neighbor]=true
			queue.append([neighbor,first])
	return "Check the field sketchbook for passage."

static func scenery(w):
	var c:Node2D=w.marks
	var t:float=w.elapsed
	match w.area:
		"Coast":
			if w.model.s.time>=1020 or w.model.s.time<420:
				var lamp:=Vector2(882,373)
				var ray:=Vector2.from_angle(-.22+sin(t*.48)*.4)*230
				c.draw_colored_polygon(PackedVector2Array([lamp,lamp+ray.rotated(-.06),lamp+ray.rotated(.06)]),Color(1,.89,.55,.20))
		"Frost":
			for i in 5:
				var p:=fposmod(t*.32+i*.2,1)
				var lodge:Vector2=w.Expansion.LANDMARKS.Frost[2]
				c.draw_circle(lodge+Vector2(18+p*18,-62-p*32),2+p*4,Color(.85,.88,.9,(1-p)*.6))
		"Desert":
			var at:=Vector2(405,410)
			c.draw_line(at,at+Vector2(0,31),Color("#634a32"),3)
			c.draw_set_transform(at,t*.62)
			c.draw_texture_rect(w.tex.wheel,Rect2(-18,-18,36,36),false)
			c.draw_set_transform(Vector2.ZERO)
		"Farm":
			for key:String in w.model.s.decor:
				var cell:=key.split(",")
				var at:=Vector2(int(cell[0])*32+16,int(cell[1])*32+26)
				if w.model.s.decor[key]=="bench" and w.model.season() in [1,6,7]:
					for i in 9:
						var dot:=Vector2(i*3-12,-10+(i%3))
						c.draw_rect(Rect2(at+dot,Vector2(3,2)),Color("#f4c1c9") if w.model.season()==1 else Color("#e4eff1"))
				if w.model.s.decor[key]=="lantern" and w.model.s.time>=1050:
					c.draw_circle(at+Vector2(0,-17),14,Color(1,.72,.27,.14))
					c.draw_circle(at+Vector2(0,-17),4,Color(1,.81,.43,.72))

