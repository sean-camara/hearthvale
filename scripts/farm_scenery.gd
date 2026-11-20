extends RefCounted

# Positions are world-space foot anchors. The central lane stays clear for navigation.
const GROVES = [
	["oak", 112, 264, 1.10], ["oak", 176, 229, .96], ["pine", 217, 195, .84],
	["oak", 284, 199, 1.09], ["pine", 399, 196, 1.05], ["oak", 473, 217, 1.07],
	["cherry", 552, 276, .97], ["oak", 635, 224, 1.11], ["pine", 738, 232, 1.03],
	["oak", 801, 290, .98], ["oak", 184, 325, .76], ["pine", 126, 422, .86],
	["oak", 153, 502, .83], ["cherry", 191, 611, .88], ["pine", 759, 483, .93],
	["oak", 797, 565, 1.08], ["pine", 739, 640, 1.13], ["oak", 571, 722, .98]
]
const BORDERS = [
	["flowers",215,323,.74],["shrub",246,321,.78],["flowers",268,324,.8],
	["flowers",413,283,.86],["rock",463,279,.62],["shrub",475,293,.72],
	["flowers",512,307,.94],["shrub",591,278,.7],["flowers",605,298,.73],
	["lanternpost",154,339,.78],["banner",538,316,.84],["lanternpost",628,321,.68],
	["shrub",732,331,.76],["flowers",752,326,.9],["rock",736,410,.7],
	["sunflowers",196,448,.94],["rock",222,474,.81],["flowers",213,480,.77],
	["shrub",224,419,.69],["lanternpost",191,412,.9],["flowers",205,397,.82],
	["shrub",665,547,.7],["flowers",657,556,.7],["sunflowers",721,522,.86],
	["rock",728,543,.8],["flowers",723,548,.9],["rock",223,558,.72],["sunflowers",209,468,1.1],["flowers",243,471,.68],["shrub",727,430,.74],
	["shrub",259,595,.8],["flowers",359,597,.75],["shrub",550,600,.73]
]
# Fence locations describe the individual segments visible in the playable world.
const RAILS = [[199,326,2],[500,315,2],[244,584,3],[472,584,3],[745,514,1]]

static func populate(world):
	for spec in GROVES:
		var at:=Vector2(spec[1],spec[2])
		world.prop("pear-"+str(world.model.season()) if at==Vector2(552,276) else spec[0],at,spec[3])
		world.barriers.append(Rect2(at-Vector2(6,8),Vector2(12,9)))
	for spec in BORDERS:
		if world.model.season()>=6 and spec[0] in ["flowers","sunflowers"]:continue
		world.prop(spec[0],Vector2(spec[1],spec[2]),spec[3])
	for group in RAILS:
		for i in range(group[2]):
			var at:=Vector2(group[0]+i*40,group[1])
			world.prop("rail",at)
			world.barriers.append(Rect2(at-Vector2(20,4),Vector2(40,5)))
	for at in [Vector2(336,299),Vector2(345,314),Vector2(339,329)]:
		world.ground_detail("stepping-stones",at,.88)
	for spec in [
		["well",607,287,.85],["pots",620,305,.85],["stone-wall",439,288,.89],
		["planter-seat",173,301,.84],["tall-grass",231,385,.7],
		["tall-grass",209,510,.84],["tall-grass",686,502,.78],
		["tall-grass",703,422,.68],["tall-grass",647,449,.72],
		["daisies",226,373,.76],["daisies",693,409,.69],
		["lavender",247,301,.85],["lavender",195,384,.78],
		["lavender",673,500,.79],["daisies",221,527,.84],
		["daisies",483,301,.86],["daisies",713,229,.9],
	]:
		if world.model.season()>=6 and spec[0] in ["daisies","lavender"]:continue
		world.prop(spec[0],Vector2(spec[1],spec[2]),spec[3])
	for rect in [Rect2(584,269,46,17),Rect2(411,280,56,8),Rect2(150,291,45,10)]:
		world.barriers.append(rect)


static func populate_village(world):
	for spec in [
		["well",460,256,.88],["stone-wall",661,277,1],
		["planter-seat",416,276,.88],["pots",618,288,.88],
		["oak",279,234,.95],["cherry",641,261,.95],
		["pine",784,293,.83],["daisies",705,295,.8],
		["tall-grass",759,378,.7],["lavender",756,406,.78],
		["daisies",896,410,.78],["oak",859,467,.98],
		["pine",667,472,1.05],["oak",238,496,.92],
		["shrub",312,277,.88],["shrub",627,467,.8],
	]:
		world.prop(spec[0],Vector2(spec[1],spec[2]),spec[3])
	world.barriers.append(Rect2(434,235,52,18))
	world.barriers.append(Rect2(632,267,58,9))
	world.barriers.append(Rect2(395,266,42,9))
 
static func populate_grove(world):
	for spec in [
		["pine",117,231,1.2],["pine",242,195,1.15],["oak",334,226,1.22],["pine",431,212,1.14],
		["pine",553,182,1.03],["pine",610,198,.85],["oak",743,196,1.04],["pine",818,222,1.04],
		["oak",988,231,1.16],["pine",1064,314,1.19],["pine",1053,430,1.12],["pine",1017,620,1.19],
		["oak",911,675,1.17],["pine",832,699,1.02],["oak",632,688,1.1],["pine",576,660,1.0],
		["oak",426,635,1.04],["pine",341,648,1.1],["oak",220,672,.98],["pine",114,536,1.03],
		["pine",102,407,1.06],["oak",169,314,1.1],["pine",530,290,.79],["oak",624,369,1.15],
		["pine",603,461,.96],["pine",841,432,.91],["oak",865,545,1.1],["pine",926,601,.91],
		["bank-plants",289,451,.84],["bank-plants",482,302,.78],["bank-plants",527,427,.83],
		["lilies",332,433,.77],["lilies",462,397,.92],["lilies",415,462,.81],
		["lanternpost",501,512,.75],
		["planter-seat",592,522,.82],["lavender",647,539,.9],["shrub",561,551,1.03],
		["daisies",256,491,.92],["lavender",805,562,1.06],["rock",1030,478,1.25],
		["lanternpost",697,676,.91],["stone-wall",786,692,.91],
	]:
		var at:=Vector2(spec[1],spec[2])
		world.prop("pear-"+str(world.model.season()) if at==Vector2(552,276) else spec[0],at,spec[3])
		if spec[0] in ["oak","pine","stone-wall","planter-seat"] and world.Trails.distance_to_trail("Grove",at)>22:
			world.barriers.append(Rect2(at-Vector2(10,10),Vector2(20,11)))
	world.spot("Fish Alderwood Pond","dock-lantern",Vector2(405,493),.87)
	world.build_stone_bridge()
	world.Rooms.place_sign(world,Vector2(650,710),"Willowbrook","↓")
	world.targets["Trail to Willowbrook"]=Vector2(675,716)
	world.show_resource_nodes()
