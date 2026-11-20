extends RefCounted

const Rooms=preload("res://scripts/arcade_rooms.gd")
const Expansion=preload("res://scripts/expansion.gd")
const Alchemy:="Maelin’s apothecary"
const ForestLodge:="Elderwood field lodge"
const Pasture:="South pasture"
const Stock:="Livestock board"
const Icons:={"moonreed":"marsh-lily","dew-tonic":"tonic","stone-salve":"tonic","fodder":"hay","goat-milk":"tonic","soft-wool":"sheep"}
const Art:=["marsh-hut","forest-lodge","trail-shelter","observatory","barn","sheep-shelter","maelin","fenn","sheep","goat","tonic","marsh-lily","still","star-rug","cauldron","heath","trough","hay","alchemy-room","grove-trail","village-trail"]
const Animals:={"goat":["Goat",90,"goat-milk",Vector2(731,449)],"sheep":["Sheep",115,"soft-wool",Vector2(375,448)]}
const Brews:={"dew-tonic":{"moonreed":1,"herb":1},"stone-salve":{"moonreed":1,"woodland-cap":1}}
const MarshDoor:=Vector2(485,521)
const ForestDoor:=Vector2(723,496)
const FarmGate:=Vector2(822,626)

static func progress(model)->Dictionary:
	return model.s.expansion.projects

static func asset(id:String)->String:
	return "res://assets/trails/"+id+".png"

static func load_art(world):
	for id:String in Art:world.tex[id]=load(asset(id))

static func decorate(world):
	var p:=progress(world.model)
	match world.area:
		"Marsh":
			for at in [Vector2(233,278),Vector2(375,303),Vector2(520,280),Vector2(742,279),Vector2(601,319),Vector2(653,310),Vector2(559,318),Vector2(963,474),Vector2(1007,471)]:
				world.prop("marsh-lily",at,.62)
			world.spot(Alchemy,"marsh-hut",MarshDoor,.98,Vector2(76,29))
			Rooms.place_sign(world,MarshDoor+Vector2(51,10),"Maelin’s apothecary","",true)
			for at in [Vector2(461,538),Vector2(804,458)]:
				world.spot("Moonreed bed %d"%int(at.x),"marsh-lily",at,.55)
			world.spot("Reed basket","basket",Vector2(573,529),.57)
			world.prop("lanternpost",Vector2(669,428),.68)
			world.prop("lanternpost",Vector2(545,516),.62)
			for at in [Vector2(899,559),Vector2(985,576),Vector2(1065,589)]:
				world.prop("dock-lantern",at,.64)
			world.prop("marsh-reeds",Vector2(1007,508),.71)
			Rooms.place_sign(world,Vector2(728,444),"Mistfen fishing","↑")
		"Forest":
			world.spot(ForestLodge,"forest-lodge",ForestDoor,.93,Vector2(66,29))
			Rooms.place_sign(world,ForestDoor+Vector2(52,3),"Field lodge","",true)
			world.spot("Forest cache","chest",Vector2(589,523),.68)
		"Grove":
			world.spot("Trail shelter","trail-shelter",Vector2(144,556),.92,Vector2(59,26))
			world.prop("lanternpost",Vector2(79,581),.75)
			world.prop("lanternpost",Vector2(225,556),.75)
			world.prop("planter-seat",Vector2(195,583),.68)
		"Farm":
			world.spot(Pasture,"sheep-shelter" if p.get("pasture-open",false) else "rail",FarmGate,.76)
			Rooms.place_sign(world,FarmGate+Vector2(51,8),"South pasture","↓")
		"AlchemyRoom":
			world.ground_detail("alchemy-room",Vector2(576,370),1)
			world.ground_detail("star-rug",Vector2(575,429),1)
			world.spot("Alchemy bench","still",Vector2(480,352),.9,Vector2(65,32))
			world.spot("Maelin’s shop","cauldron",Vector2(680,360),.86,Vector2(60,30))
			world.targets["Leave apothecary"]=Vector2(576,507)
			world.barriers.append(Rect2(301,283,550,42))
		"Pasture":
			world.ground_detail("region-Pasture",Vector2(576,384),1)
			world.spot(Stock,"barn",Vector2(529,409),1.22,Vector2(102,45))
			world.spot("Cut pasture hay","hay",Vector2(700,551),.95)
			world.spot("Back to Hearthvale","stone-wall",Vector2(564,694),.8)
			for center in [Vector2(375,449),Vector2(731,449)]:
				for i in range(-2,3):
					world.prop("rail",center+Vector2(i*29,-36),.76)
				world.prop("trough",center+Vector2(-45,13),.82)
			world.prop("sheep-shelter",Vector2(350,402),.84)
			for kind:String in Animals:
				if p.has("animal-"+kind):
					var at:Vector2=Animals[kind][3]
					world.spot("Tend "+kind,kind,at,.57)
					world.resource_sprites["animal-"+kind]=world.actors.get_child(-1)
			for at in [Vector2(278,399),Vector2(832,377),Vector2(330,635),Vector2(769,658)]:
				world.prop("oak",at,.95)
			Rooms.place_sign(world,Vector2(587,407),"Livestock board","",true)

static func update(world):
	if world.area!="Pasture":return
	for kind:String in Animals:
		var sprite:Sprite2D=world.resource_sprites.get("animal-"+kind)
		if sprite==null:continue
		var base:Vector2=Animals[kind][3]
		var phase:float=world.elapsed*.57+(1.2 if kind=="goat" else .0)
		sprite.position=(base+Vector2(sin(phase)*28,cos(phase*.75)*10)).round()
		sprite.flip_h=cos(phase)<0
		world.targets["Tend "+kind]=sprite.position

static func handle(game,id:String)->bool:
	var m=game.model
	var p:=progress(m)
	match id:
		Alchemy:
			if m.s.time<420 or m.s.time>=1200:game.feedback("Maelin opens from 07:00 to 20:00.")
			else:travel(game,"AlchemyRoom",Vector2(576,472))
		"Leave apothecary":
			travel(game,"Marsh",MarshDoor+Vector2(0,26))
		Pasture:
			if p.get("pasture-open",false):travel(game,"Pasture",Vector2(563,658))
			else:game.show_page(Pasture)
		"Back to Hearthvale":
			travel(game,"Farm",FarmGate+Vector2(0,-24))
		"Forest cache":
			gather(game,id,"woodland-cap",1,"Found a mushroom beside the lodge.")
		"Cut pasture hay":
			gather(game,id,"fodder",3,"Cut three bundles of hay.")
		"Reed basket":
			gather(game,id,"fodder",2,"Found two bundles of marsh hay.")
		ForestLodge,"Trail shelter",Stock,"Maelin’s shop","Alchemy bench","Tend sheep","Tend goat","Fieldwork":
			game.show_page(id)
		_:
			if not id.begins_with("Moonreed bed"):return false
			gather(game,id,"moonreed",2,"Cut two moonreed stalks.")
	return true

static func travel(game,area:String,at:Vector2):
	game.close_page()
	game.relocate(area,at,Vector2.UP)

static func gather(game,key:String,item:String,count:int,message:String):
	var m=game.model
	var p:=progress(m)
	if int(p.get(key,-1))==int(m.s.day):
		game.feedback("This spot replenishes tomorrow.")
	elif m.change(item,count):
		p[key]=int(m.s.day)
		Expansion.record(m,item,game.Routes.NAMES[game.world.area])
		game.store()
		game.feedback(message)
	else:game.feedback("Make room in your satchel.")

static func page(game,id:String)->bool:
	var m=game.model
	var p:=progress(m)
	match id:
		"Fieldwork":
			game.note("Find Maelin’s apothecary in Mistfen. Collect moonreed along the boardwalk. Elderwood’s field lodge trades supplies for foragers. The trail shelter in Alderwood marks the forest exit.")
			game.note("Open the south pasture at your farm gate with 80 crowns and six wood. Raise goats and sheep and feed them daily.")
		"Maelin’s shop":
			game.MenuCards.header(game,"Maelin’s supplies","Wallet · %d crowns"%int(m.s.coins),game.world.tex["still"])
			for item:Array in [["moonreed",9],["dew-tonic",34],["stone-salve",40]]:
				game.MenuCards.product(game,m.item_name(item[0]),item[1],"",buy.bind(game,item[0],item[1],id),game.world.tex[Icons[item[0]]])
			game.row("Learn alchemy",game.show_page.bind("Alchemy bench"))
		"Alchemy bench":
			game.sketch_entry("The brass still",game.world.tex["still"])
			if not p.get("alchemy-trained",false):
				game.note("Maelin asks for two fresh moonreed stalks to test a batch. Take the boardwalk past the hut to find them.")
				game.row("Bring two moonreed",learn.bind(game))
			else:
				game.note("Stillwater tonic widens the next fishing window. Stoneleaf salve restores mining energy. Use either from the Satchel.")
				for item:String in Brews:
					var parts:=PackedStringArray()
					for ingredient:String in Brews[item]:parts.append(m.item_name(ingredient))
					game.row("Brew "+m.item_name(item)+" · "+" + ".join(parts),brew.bind(game,item),game.world.tex.tonic)
		ForestLodge:
			game.note("Fenn trades dried mint and trail supplies by the old oak. Check the cache near the ruins each morning.")
			game.MenuCards.product(game,"Creek mint",7,"",buy.bind(game,"herb",7,id),game.world.tex.mint)
			game.MenuCards.product(game,"Hay",6,"",buy.bind(game,"fodder",6,id),game.world.tex.hay)
			game.MenuCards.product(game,"Creek bait",5,"",buy.bind(game,"bait",5,id),game.arcade_icon("bait"))
		"Trail shelter":
			game.note("West follows the gravel to Elderwood. North climbs toward Ironpeak. The southern road leads to Willowbrook.")
			game.row("Rest at the shelter",rest.bind(game))
		Pasture:
			game.sketch_entry("The south pasture",game.world.tex.barn)
			game.note("Repair the paddocks and open the trail. Cost · 80 crowns and six wood.")
			game.row("Open south pasture",open_pasture.bind(game))
		Stock:
			game.note("Buy one goat and one sheep. Feed each a bundle of hay to collect its product the next morning.")
			for kind:String in Animals:
				if p.has("animal-"+kind):game.note(Animals[kind][0]+" is in its paddock.")
				else:game.MenuCards.product(game,"Buy "+Animals[kind][0],Animals[kind][1],"",adopt.bind(game,kind),game.world.tex[kind])
			game.MenuCards.product(game,"Bundle of hay",6,"",buy.bind(game,"fodder",6,id),game.world.tex.hay)
		"Tend sheep","Tend goat":
			var kind:=id.trim_prefix("Tend ")
			var record:Dictionary=p.get("animal-"+kind,{})
			game.sketch_entry(Animals[kind][0],game.world.tex[kind])
			if int(record.get("fed",-1))==int(m.s.day):game.note("Fed today.")
			else:game.row("Feed one hay",feed.bind(game,kind))
			if int(record.get("stock",0))>0:game.row("Collect "+m.item_name(Animals[kind][2]),collect.bind(game,kind))
		_:
			return false
	return true

static func rest(game):
	game.close_page()
	game.world.sitting=true
	game.feedback("You rest under the shelter and listen to the pond.")

static func buy(game,item:String,cost:int,page_id:String):
	var m=game.model
	if int(m.s.coins)<cost:
		game.note("You need %d more crowns."%(cost-int(m.s.coins)))
	elif m.change(item,1):
		m.s.coins-=cost
		game.store()
		game.show_page(page_id)
	else:game.note("Make room in your satchel.")

static func learn(game):
	var m=game.model
	if progress(m).get("alchemy-trained",false):return
	if not m.change("moonreed",-2):
		game.note("Bring two fresh moonreed stalks.")
		return
	progress(m)["alchemy-trained"]=true
	m.s.coins+=24
	game.store()
	game.show_page("Alchemy bench")
	game.note("Maelin teaches both recipes and pays 24 crowns for the reeds.")

static func brew(game,item:String):
	var m=game.model
	for ingredient:String in Brews[item]:
		if m.qty(ingredient)<int(Brews[item][ingredient]):
			game.note("You need "+m.item_name(ingredient)+".")
			return
	if not m.change(item,1):return
	for ingredient:String in Brews[item]:m.change(ingredient,-int(Brews[item][ingredient]))
	game.store()
	game.show_page("Alchemy bench")
	game.note("Brewed "+m.item_name(item)+".")

static func drink(game,item:String):
	var m=game.model
	if item=="stone-salve" and (game.world.area!="Mine" or float(m.s.mine.energy)>=100):
		game.note("Use this in the mine when your energy is low.")
		return
	if not m.change(item,-1):return
	if item=="dew-tonic":progress(m)["tonic-cast"]=true
	else:m.s.mine.energy=minf(100,float(m.s.mine.energy)+30.0)
	game.store()
	game.close_page()
	game.feedback("Your next cast is steadier." if item=="dew-tonic" else "Recovered 30 mining energy.")

static func open_pasture(game):
	var m=game.model
	if progress(m).get("pasture-open",false):return
	if int(m.s.coins)<80 or not m.change("wood",-6):
		game.note("Bring 80 crowns and six wood.")
		return
	m.s.coins-=80
	progress(m)["pasture-open"]=true
	travel(game,"Pasture",Vector2(563,658))

static func adopt(game,kind:String):
	var m=game.model
	var key:="animal-"+kind
	if progress(m).has(key):return
	var cost:int=Animals[kind][1]
	if int(m.s.coins)<cost:
		game.note("Save %d crowns for this animal."%cost)
		return
	m.s.coins-=cost
	progress(m)[key]={"fed":-1,"stock":0}
	game.world.enter("Pasture",game.world.pos)
	game.store()
	game.show_page(Stock)

static func feed(game,kind:String):
	var m=game.model
	var record:Dictionary=progress(m)["animal-"+kind]
	if int(record.fed)==int(m.s.day):return
	if not m.change("fodder",-1):
		game.note("Cut hay near the paddocks or buy a bundle from the livestock board.")
		return
	record.fed=int(m.s.day)
	game.store()
	game.show_page("Tend "+kind)

static func collect(game,kind:String):
	var m=game.model
	var record:Dictionary=progress(m)["animal-"+kind]
	if int(record.stock)>0 and m.change(Animals[kind][2],int(record.stock)):
		record.stock=0
		game.store()
		game.show_page("Tend "+kind)

static func overnight(model):
	var p:=progress(model)
	for kind:String in Animals:
		if not p.has("animal-"+kind):continue
		var record:Dictionary=p["animal-"+kind]
		if int(record.fed)==int(model.s.day):record.stock=mini(8,int(record.stock)+1)

