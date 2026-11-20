extends RefCounted

const NAMES := {
	"Lakes":"Silverwater Lakes", "Coast":"Sunshore Coast", "Forest":"Elderwood Forest",
	"Marsh":"Mistfen Marshes", "Plains":"Goldenreach Plains", "Desert":"Emberglass Desert",
	"Highlands":"Ironpeak Highlands", "Frost":"Frostpine Mountains",
	"Isles":"Moonpetal Isles", "Below":"The Forgotten Below",
}
const NS := Vector2(865,905)
const EW := Vector2(590,630)
const LINKS := {
	"Village":{"south":["Lakes","north",NS],"east":["Plains","west",EW]},
	"Grove":{"north":["Highlands","south",NS],"west":["Forest","east",EW]},
	"Lakes":{"north":["Village","south",NS],"south":["Coast","north",NS]},
	"Coast":{"north":["Lakes","south",NS]},
	"Plains":{"west":["Village","east",EW],"east":["Desert","west",EW]},
	"Desert":{"west":["Plains","east",EW]},
	"Forest":{"east":["Grove","west",EW],"west":["Marsh","east",EW]},
	"Marsh":{"east":["Forest","west",EW]},
	"Highlands":{"south":["Grove","north",NS],"north":["Frost","south",NS]},
	"Frost":{"south":["Highlands","north",NS]},
}
const ITEMS := {
	"moonreed":["Moonreed",8,"Fresh stalks from Mistfen’s reed beds."],
	"dew-tonic":["Stillwater tonic",28,"Drink at a fishing spot to steady the next cast."],
	"stone-salve":["Stoneleaf salve",32,"Restores 30 mining energy when used."],
	"fodder":["Hay",4,"One bundle feeds one pasture animal for a night."],
	"goat-milk":["Goat milk",19,"Fresh milk from the pasture."],
	"soft-wool":["Soft wool",29,"A clean fleece from a well-fed sheep."],

	"orchard-apple":["Orchard apple",12,"A tart fruit from the restored south orchard."],
	"orchard-pear":["Golden pear",15,"A fragrant pear from the grafted row."],
	"orchard-jar":["Orchard preserves",36,"Pip buys these by the jar at the Copper Kettle."],
	"ice-quartz":["Ice quartz",32,"A clear vein from the Frostpine cave."],
	"lake-reed":["Silver reed",7,"A pale reed from the lake shallows."],
	"tide-shell":["Sunshore shell",18,"You can set it on the cottage shelf."],
	"woodland-cap":["Elderwood mushroom",12,"A copper cap from under the old trees."],
	"frogmint":["Frogmint",16,"Its split leaf smells of mint and rain."],
	"prairie-clover":["Prairie clover",8,"A flower from the open grasslands."],
	"glassbloom":["Glassbloom",22,"The oasis flower opens at dusk."],
	"highland-quartz":["Highland quartz",21,"The vein shines white in sunlight."],
	"winter-sage":["Winter sage",19,"The warm spring keeps its leaves green."],
	"moon-fruit":["Moonpetal fruit",31,"A pale fruit that keeps its glow after sunset."],
	"river-glass":["River glass",33,"The underground river polished it smooth."],
	"creek-pottery":["Willow-pattern shard",0,"This glaze matches a plate at Linn’s house."],
	"blossom-honey":["Blossom honey",24,"Sweet with a hint of orchard flowers."],
	"herb-honey":["Herb honey",24,"Honey scented with the herbs nearest the hive."],
	"creek-soup":["Creek chowder",21,"Fish from the valley and herbs from its banks."],
}
const DISCOVERIES := {
	"Lakes":["lake-reed",Vector2(667,535),"Reed bed","tall-grass"],
	"Coast":["tide-shell",Vector2(697,492),"Tide pool","rock"],
	"Forest":["woodland-cap",Vector2(437,460),"Mushroom hollow","mine-mushrooms"],
	"Marsh":["frogmint",Vector2(662,538),"Frogmint patch","mint"],
	"Plains":["prairie-clover",Vector2(659,536),"Clover meadow","flowers"],
	"Desert":["glassbloom",Vector2(487,526),"Oasis bloom","flowers"],
	"Highlands":["highland-quartz",Vector2(673,521),"Quartz seam","mine-crystal"],
	"Frost":["winter-sage",Vector2(690,505),"Spring herbs","mint"],
	"Isles":["moon-fruit",Vector2(713,527),"Moonpetal orchard","orchard"],
	"Below":["river-glass",Vector2(676,522),"River glass","mine-crystal"],
}
const LANDMARKS := {
	"Lakes":["Waterfall trail","stone-bridge",Vector2(510,429)],
	"Coast":["Lighthouse ferry","lanternpost",Vector2(882,439)],
	"Forest":["Elderwood ruins","stone-wall",Vector2(600,427)],
	"Marsh":["Frogwatch shelter","market",Vector2(600,438)],
	"Plains":["Produce wagons","market",Vector2(697,443)],
	"Desert":["Oasis irrigation","well",Vector2(592,440)],
	"Highlands":["Quarry lift","mine-lift",Vector2(572,446)],
	"Frost":["Geothermal shelter","homestead",Vector2(598,444)],
	"Isles":["Return ferry","mine-dock",Vector2(891,462)],
	"Below":["Waterfall stair","stone-bridge",Vector2(574,471)],
}
const FISHING := {
	"Lakes":["lake",Vector2(497,382),"Silverwater dock"],
	"Coast":["sea",Vector2(623,381),"Sunshore pier"],
	"Marsh":["marsh",Vector2(688,382),"Reedwater bank"],
	"Frost":["ice",Vector2(697,378),"Ice fishing hole"],
	"Isles":["sea",Vector2(561,366),"Island pier"],
	"Below":["below",Vector2(777,360),"Underground river"],
}

static func defaults() -> Dictionary:
	return {"intro":false,"parcel":false,"lessons":{},"first_harvest":false,"oren_note":false,"linn_supper":false,"linn_cooked":false,"visited":{},"projects":{},"finds":{},"hive":"","honey_day":-1,"stall_day":-1,"stall_sales":[],"shell_display":false}

static func low_tide(model) -> bool:
	return (int(model.s.time)+180*(int(model.s.day)%2))%720 < 300

static func steps_exposed(model)->bool:
	return model.season() in [4,5] and low_tide(model)

static func low_creek(model) -> bool:
	return model.weather(model.s.day)!="Showers" and model.season() not in [1,3]

static func gather(model, region:String) -> String:
	var spec:Array=DISCOVERIES[region]
	if int(model.s.picked.get(spec[0],-1))==int(model.s.day):return "Give it until tomorrow to replenish."
	match region:
		"Coast":
			if not low_tide(model):return "The pool is underwater. Check the tide at the lighthouse."
		"Marsh":
			if model.weather(model.s.day)!="Showers" and model.season()!=3:return "Look for fresh frogmint in rain or during Raincall."
		"Desert":
			if not model.s.expansion.projects.get("oasis",false):return "Repair the irrigation at the oasis first."
			if model.s.time<1020:return "The buds are closed. Check back after 17:00."
		"Highlands":
			if not model.s.tools.get("pickaxe",false):return "Bring a pickaxe from Willowbrook."
	if not model.change(spec[0],1):return "Make room in your satchel."
	model.s.picked[spec[0]]=model.s.day
	record(model,spec[0],NAMES[region])
	return "Found "+model.item_name(spec[0])+"."

static func record(model,id:String,place:String):
	if not model.s.expansion.finds.has(id):
		model.s.expansion.finds[id]={"place":place,"day":int(model.s.day),"weather":model.weather(model.s.day)}

static func complete_project(model,id:String,cost:Dictionary) -> bool:
	if model.s.expansion.projects.has(id):return false
	for item:String in cost:
		if model.qty(item)<int(cost[item]):return false
	for item:String in cost:model.change(item,-int(cost[item]))
	model.s.expansion.projects[id]=true
	return true

