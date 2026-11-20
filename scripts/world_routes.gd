extends RefCounted

const WIDTH:=1152
const HEIGHT:=768
const LANDING:=34.0
const RIVER_LANE:=Vector2(315,353)
const WOOD_LANE:=Vector2(711,755)
const Stock=preload("res://scripts/arcade_stock.gd")
const Expansion=preload("res://scripts/expansion.gd")
static var OUTDOORS:Array=["Farm","Village","Grove","Pasture"]+Expansion.NAMES.keys()
const BASE_NAMES:={
	"Farm":"Hearthvale Farmlands",
	"Pasture":"South pasture",
	"AlchemyRoom":"Maelin’s apothecary",
	"Village":"Willowbrook Village",
	"Grove":"Alderwood Grove",
	"Mine":"Alderwood Mine",
	"SlateSpur":"Slate quarry spur",
	"FloodedSpur":"Flooded side chamber",
	"IceCave":"Frostpine Ice Cave",
	"Cottage":"The Hearth Room",
	"Arcade":"Willowbrook Arcade",
	"SeedLoft":"Iona’s Seed Loft",
	"BakerLoft":"Pip’s Attic",
	"Mercantile":"Willowbrook Mercantile",
	"Bakery":"The Copper Kettle",
	"Herbarium":"Fern & Thistle House",
	"CraftsHouse":"The Stave House",
	"RiverLodge":"Oren’s River Lodge",
}
static var NAMES:Dictionary=make_names()

static func make_names()->Dictionary:
	var names:=BASE_NAMES.merged(Expansion.NAMES)
	for title:String in Stock.STORES:names["Shop:"+title]=title
	return names

static func map_region(area:String)->String:
	if area in OUTDOORS:return area
	if area.begins_with("Shop:"):return "Village"
	var parent:String=DOORS.get(area,["Village"])[0]
	return parent if parent in OUTDOORS else map_region(parent)
const LINKS:={
	"Farm":{"east":["Village","west",RIVER_LANE]},
	"Village":{"west":["Farm","east",RIVER_LANE],"north":["Grove","south",WOOD_LANE]},
	"Grove":{"south":["Village","north",WOOD_LANE]},
}
const DOORS:={
	"AlchemyRoom":["Marsh",Vector2(485,521),Vector2(485,547)],
	"Pasture":["Farm",Vector2(822,626),Vector2(822,602)],
	"SlateSpur":["Mine",Vector2(369,480),Vector2(369,480)],
	"FloodedSpur":["Mine",Vector2(789,405),Vector2(789,405)],
	"Mine":["Grove",Vector2(960,467),Vector2(960,487)],
	"IceCave":["Frost",Vector2(442,513),Vector2(450,560)],
	"Cottage":["Farm",Vector2(341,284),Vector2(346,301)],
	"Arcade":["Village",Vector2(982,308),Vector2(982,339)],
	"SeedLoft":["Mercantile",Vector2(798,338),Vector2(798,351)],
	"BakerLoft":["Bakery",Vector2(798,339),Vector2(798,351)],
	"Mercantile":["Village",Vector2(355,247),Vector2(355,271)],
	"Bakery":["Village",Vector2(732,253),Vector2(732,275)],
	"Herbarium":["Village",Vector2(621,551),Vector2(621,574)],
	"CraftsHouse":["Village",Vector2(392,599),Vector2(392,622)],
	"RiverLodge":["Village",Vector2(251,518),Vector2(251,541)],
}

static func west_bank(y:float)->float:
	return 972.0+20.0*sin(y/78.0)

static func east_bank(y:float)->float:
	return 171.0+19.0*sin((y+27.0)/72.0)

static func pond(at:Vector2)->bool:
	return ((at-Vector2(400,378))/Vector2(141,103)).length_squared()<1.0

static func wet(region:String,at:Vector2)->bool:
	match region:
		"Farm":return at.x>west_bank(at.y) and not lane_has(RIVER_LANE,at.y)
		"Village":return at.x<east_bank(at.y) and not lane_has(RIVER_LANE,at.y)
		"Grove":
			if pond(at):return true
			var stream:=447+19*sin((at.y-460)/65)
			return at.y>=446 and absf(at.x-stream)<15 and not lane_has(Vector2(492,516),at.y)
	return false

static func lane_has(lane:Vector2,value:float)->bool:
	return value>=lane.x and value<=lane.y

static func links(region:String) -> Dictionary:
	return LINKS.get(region,{}).merged(Expansion.LINKS.get(region,{}))

static func edge(region:String,at:Vector2,velocity:Vector2)->String:
	var side:=""
	if at.x>=WIDTH-15 and velocity.x>0:side="east"
	elif at.x<=15 and velocity.x<0:side="west"
	elif at.y<=27 and velocity.y<0:side="north"
	elif at.y>=HEIGHT-17 and velocity.y>0:side="south"
	var exits:=links(region)
	if not exits.has(side):return ""
	var across:=at.y if side in ["east","west"] else at.x
	return side if lane_has(exits[side][2],across) else ""

static func destination(region:String,side:String,at:Vector2)->Dictionary:
	var link:Array=links(region).get(side,[])
	if link.is_empty():return {}
	var lane:Vector2=link[2]
	var entry:=Vector2.ZERO
	var facing:=Vector2.ZERO
	match link[1]:
		"west":
			entry=Vector2(LANDING,clampf(at.y,lane.x,lane.y))
			facing=Vector2.RIGHT
		"east":
			entry=Vector2(WIDTH-LANDING,clampf(at.y,lane.x,lane.y))
			facing=Vector2.LEFT
		"north":
			entry=Vector2(clampf(at.x,lane.x,lane.y),LANDING+5.0)
			facing=Vector2.DOWN
		"south":
			entry=Vector2(clampf(at.x,lane.x,lane.y),HEIGHT-LANDING)
			facing=Vector2.UP
	return {"area":link[0],"position":entry,"facing":facing}

