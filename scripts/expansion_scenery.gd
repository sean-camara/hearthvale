extends RefCounted

const Expansion=preload("res://scripts/expansion.gd")
const Trails=preload("res://scripts/valley_trails.gd")
const Rooms=preload("res://scripts/arcade_rooms.gd")

static func decorate(world):
	var region:String=world.area
	if region in ["Village","Grove"]:
		for side:String in Expansion.LINKS[region]:
			var link:Array=Expansion.LINKS[region][side]
			var at:Vector2={"north":Vector2(885,64),"south":Vector2(850,716),"east":Vector2(1090,577),"west":Vector2(65,603)}[side]
			Rooms.place_sign(world,at,Expansion.NAMES[link[0]],{"north":"↑","south":"↓","east":"→","west":"←"}[side])
	if not Expansion.NAMES.has(region):return
	var theme:Array={
		"Lakes":["oak","dunes","lavender","rock"],"Coast":["rock","daisies","dunes","rock"],
		"Forest":["oak","pine","shrub","flowers"],"Marsh":["dunes","shrub","lavender","rock"],
		"Plains":["sunflowers","tall-grass","rock","flowers"],"Desert":["rock","cactus","rock","palm"],
		"Highlands":["rock","pine","lavender","rock"],"Frost":["snow-pines","rock","snow-pines","tall-grass"],
		"Isles":["palm","flowers","orchard","rock"],"Below":["rock","crystals","mine-mushrooms","rock"],
	}[region]
	var rng:=RandomNumberGenerator.new()
	rng.seed=715+Expansion.NAMES.keys().find(region)
	for i in range(126):
		var at:=Vector2(rng.randf_range(20,1133),rng.randf_range(35,744))
		if world.blocked(at) or Trails.distance_to_trail(region,at)<32:continue
		if at.distance_to(Expansion.LANDMARKS[region][2])<158 or at.distance_to(Expansion.DISCOVERIES[region][1])<66:continue
		var art:String=theme[i%4]
		var sprite:Sprite2D=world.prop(art,at,rng.randf_range(.42,1.04))
		if region=="Frost":sprite.self_modulate=Color("#c4dceb")
		if region=="Below":sprite.self_modulate=Color("#aab1d5")
		if art in ["pine","oak","cherry"]:world.barriers.append(Rect2(at-Vector2(6,8),Vector2(12,11)))
	compose_landmark(world,region)
	if region=="Coast":
		world.targets["Old tide steps"]=Vector2(552,381)
		world.resource_sprites["tide-steps"]=world.prop("steps-dry" if Expansion.steps_exposed(world.model) else "steps-wet",Vector2(552,381),.85)
	if region=="Coast" and world.model.s.expansion.projects.get("ferry",false):
		world.prop("pier",Vector2(779,357),.71)
	var landmark:Array=Expansion.LANDMARKS[region]
	var art:String=available_art(world,{"Marsh":"observatory","Coast":"watchlight","Forest":"vine-arch","Frost":"alpine-lodge","Isles":"pier","Plains":"wagon","Lakes":"waterfall","Below":"crystals"}.get(region,landmark[1]),landmark[1])
	world.spot("travel:landmark",art,landmark[2],.95,Vector2(33,14))
	Rooms.place_sign(world,landmark[2]+Vector2(70,0),landmark[0],"",true)
	var find:Array=Expansion.DISCOVERIES[region]
	if int(world.model.s.picked.get(find[0],-1))!=int(world.model.s.day):
		var detail:String=available_art(world,{"Coast":"pool","Forest":"forest-cap","Highlands":"quartz","Isles":"isle-orchard","Below":"quartz"}.get(region,find[3]),find[3])
		world.spot("travel:find",detail,find[1],.80)
		if region=="Coast" and world.tex.has("shell"):
			var shell:Sprite2D=world.prop("shell",find[1]+Vector2(21,3),.72)
			shell.visible=Expansion.low_tide(world.model)
			world.resource_sprites["shell-on-beach"]=shell
	if region=="Frost":
		world.spot("Frostpine ice cave","crystals",Vector2(442,513),.64)
		Rooms.place_sign(world,Vector2(403,531),"Ice cave")
	if Expansion.FISHING.has(region):
		var fish:Array=Expansion.FISHING[region]
		var at:Vector2=fish[1]
		if region in ["Coast","Lakes","Isles"]:world.prop("pier",at+Vector2(0,-17),.77)
		world.spot("travel:fish","dock-lantern",at+Vector2(29,4),.60)
	world.spot("travel:rest","planter-seat",Vector2(932,538),.86)
	for side:String in Expansion.LINKS.get(region,{}):
		var link:Array=Expansion.LINKS[region][side]
		var at:Vector2={"north":Vector2(843,55),"south":Vector2(843,716),"west":Vector2(64,570),"east":Vector2(1087,570)}[side]
		var name_:String=Expansion.NAMES.get(link[0],"Willowbrook" if link[0]=="Village" else "Alderwood Grove")
		Rooms.place_sign(world,at,name_,{"north":"↑","south":"↓","west":"←","east":"→"}[side])

static func available_art(world,id:String,fallback:String) -> String:
	return id if world.tex.has(id) else fallback

static func compose_landmark(world,region:String):
	var groups:Dictionary={
		"Lakes":[["dunes",613,361,.8],["rock",406,437,1.08],["oak",354,444,1.07],["dunes",639,487,.73]],
		"Coast":[["dunes",794,413,.71],["rock",974,443,1.0],["dunes",879,609,1.0],["daisies",753,535,.85],["rail",937,467,.92],["rail",970,467,.92],["dunes",578,499,.68]],
		"Forest":[["elder-tree",489,425,1.10],["elder-tree",715,407,1.06],["pine",380,422,1.18],["shrub",400,491,.89],["oak",344,549,1.01],["pine",805,492,1.11],["flowers",730,538,.83],["pine",584,716,1.1],["elder-tree",762,698,.92]],
		"Marsh":[["marsh-reeds",602,387,1.0],["marsh-reeds",771,410,.8],["dunes",550,527,1.28],["lilies",607,329,.9],["rock",804,526,.85]],
		"Plains":[["wagon",500,446,.82],["dunes",601,461,.77],["rail",624,488,.89],["rail",590,488,.89],["sunflowers",759,506,1.19],["sunflowers",801,505,.96]],
		"Desert":[["sand-arch",349,453,1.15],["palm",465,432,1.05],["palm",659,411,1.01],["cactus",718,524,.83],["cactus",392,539,.97],["rock",789,521,1.19],["pots",643,465,.85]],
		"Highlands":[["rock",429,454,1.65],["quartz",735,471,.85],["pine",402,505,1.28],["rock",488,507,1.13],["pine",795,479,1.09],["dock-lantern",635,517,.9]],
		"Frost":[["snow-pines",449,440,1.07],["snow-pines",750,448,1.0],["snow-pines",821,534,.91],["snow-pines",371,547,1.19],["hearth-logs",511,464,.96],["dock-lantern",668,459,.76]],
		"Isles":[["palm",771,474,1.05],["palm",623,417,1.23],["isle-orchard",554,507,.95],["palm",814,560,.79],["flowers",637,554,1.1]],
		"Below":[["crystals",461,462,1.24],["crystals",755,449,1.28],["crystals",850,573,.78],["mine-mushrooms",585,559,.93],["mine-mushrooms",710,467,.87],["rock",411,560,1.31]],
	}
	for item:Array in groups[region]:
		var at:=Vector2(item[1],item[2])
		var art:String=available_art(world,item[0],"shrub")
		world.prop(art,at,item[3])
		if art in ["elder-tree","pine","palm","snow-pines","sand-arch","crystals"]:
			world.barriers.append(Rect2(at-Vector2(15,12),Vector2(30,14)))

static func wet(region:String,at:Vector2) -> bool:
	if region=="Marsh" and ((at-Vector2(967,469))/Vector2(75,51)).length_squared()<1:return true
	if region=="Desert":
		return ((at-Vector2(506,308))/Vector2(172,92)).length_squared()<1
	if not Expansion.FISHING.has(region):return false
	var x:=at.x*.5
	var edge:=minf(338+26*sin(x/49)+8*sin(x/13),(431-x)*5.6)
	return at.y<edge
