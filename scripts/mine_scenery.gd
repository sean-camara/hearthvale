extends RefCounted

const Mine=preload("res://scripts/mine_progress.gd")
const Rooms=preload("res://scripts/arcade_rooms.gd")
const ROOM:=Rect2(312,238,532,285)
const POOL:=Rect2(704,245,126,88)

static func blocked(depth:int,at:Vector2)->bool:
	if not ROOM.has_point(at):return true
	if Mine.band(depth)==2 and POOL.has_point(at):return true
	return false

static func build(world):
	Mine.refresh(world.model)
	var depth:=int(world.model.s.mine.depth)
	var band:=Mine.band(depth)
	world.ground_detail("mine-floor-"+str(band),Vector2(576,356),1)
	for at in [Vector2(344,264),Vector2(406,249),Vector2(750,256),Vector2(825,281),Vector2(325,445),Vector2(819,469)]:
		var art:="mine-mushrooms" if band==1 else ("mine-crystal" if band==2 else "rock")
		world.prop(art,at,.74)
	world.spot("Mine descent","mine-entrance",Vector2(572,275),.48,Vector2(64,19))
	world.spot("Mine lift","mine-lift",Vector2(705,457),.63,Vector2(32,13))
	world.spot("Leave mine","dock-lantern",Vector2(576,507),.75)
	Rooms.place_sign(world,Vector2(490,218),"Level %d"%depth,"",true)
	for node:Dictionary in Mine.nodes(depth):
		var index:String=str(node.id).get_slice(":",1)
		if int(world.model.s.mine.nodes.get(node.id,0))<0:continue
		var at:Vector2=node.at
		var art:String={"stone":"rock","iron-ore":"rock","coal":"rock","copper":"item-copper","moonstone":"mine-crystal"}[node.ore]
		var sprite:Sprite2D=world.prop(art,at,.93)
		if node.ore=="iron-ore":sprite.modulate=Color("#aed0de")
		if node.ore=="coal":sprite.modulate=Color("#727383")
		world.targets["mine-node:"+index]=at
		world.barriers.append(Rect2(at-Vector2(10,7),Vector2(20,10)))
	if band==2:
		world.spot("Underground fishing","dock-lantern",Vector2(752,339),.78)
		world.prop("mine-dock",Vector2(776,322),.56)
	if depth>=5 and not world.model.s.mine.beaten.has(str(depth)):
		world.mine_beetle=world.prop("mine-beetle",Vector2(631,400),.76)

static func outdoor(world):
	if world.area=="Grove":
		world.spot("Alderwood Mine","mine-entrance",Vector2(960,467),.95,Vector2(77,29))
		world.targets["Mining kit"]=Vector2(892,492)
		Rooms.place_sign(world,Vector2(955,374),"Alderwood Mine","",true)
	if world.area=="Village" and int(world.model.s.mine.dock_stage)>=4:
		world.prop("mine-dock", Mine.DOCK+Vector2(-68,-4),1.03)
		world.prop("dock-lantern",Mine.DOCK+Vector2(-4,-11),.82)
		world.targets["Restored fishing dock"]=Mine.DOCK+Vector2(-50,-14)
		Rooms.place_sign(world,Mine.DOCK+Vector2(24,24),"Willowbrook Dock")
		world.prop("mine-supper",Mine.DOCK+Vector2(30,-36),.89)
		world.barriers.append(Rect2(Mine.DOCK+Vector2(10,-51),Vector2(42,15)))
		update_supper(world)
	if world.area=="Arcade":
		world.spot("Ves’s furnace","mine-furnace",Vector2(321,429),.57,Vector2(26,12))


static func update_supper(world):
	if world.area!="Village" or int(world.model.s.mine.dock_stage)<4:return
	var time:float=world.model.s.time
	if time>=1080 and time<1320 and int(world.model.s.day)>=int(world.model.s.mine.supper):
		world.targets["Creekside supper"]=Mine.DOCK+Vector2(30,-28)
	else:world.targets.erase("Creekside supper")
