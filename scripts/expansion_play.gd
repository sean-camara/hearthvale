extends RefCounted

const Expansion=preload("res://scripts/expansion.gd")
const Routes=preload("res://scripts/world_routes.gd")
const Life=preload("res://scripts/world_life.gd")
const SeaSeason=preload("res://scripts/season_events.gd")

static func handle(game,id:String)->bool:
	var model=game.model
	var world=game.world
	if id.begins_with("travel:"):
		match id:
			"travel:find":
				game.feedback(Expansion.gather(model,world.area))
				world.enter(world.area,world.pos)
				game.store()
			"travel:landmark":game.show_page(Expansion.LANDMARKS[world.area][0])
			"travel:fish":game.start_fishing(Expansion.FISHING[world.area][0])
			"travel:rest":sit(game,"Sit for a while and listen.")
		return true
	match id:
		"Old tide steps":
			model.s.expansion.projects["steps-sketch"]=true
			if Expansion.steps_exposed(model) and model.s.expansion.projects.has("shell-carving"):
				world.pos=Vector2(552,368)
				game.feedback("From the lowest step you can see the old ferry channel.")
			elif Expansion.steps_exposed(model):
				world.pos=Vector2(552,368)
				model.s.expansion.projects["shell-carving"]=true
				game.feedback("You descend the steps. In the last niche is a carved shell for your cottage.")
			else:game.feedback("You sketch the submerged steps. Ask Soren when the water recedes.")
			game.store()
		"Cottage step":sit(game,"You sit at the step and look out over your garden.")
		"Bridge seat":sit(game,"Willow Creek runs beneath your feet.")
		"Dock seat":sit(game,"Water laps against the boards Oren helped lay.")
		"Bedside almanac","Greenhouse","Orchard hive","Herb hive","Village archive","Player market stall":
			game.show_page(id)
		"Seed parcel":
			if model.s.expansion.parcel:return true
			if model.qty("s0")>model.CAPACITY-3 or model.qty("s1")>=model.CAPACITY:
				game.feedback("Make some room for the seed parcel.")
				return true
			model.change("s0",3)
			model.change("s1",1)
			model.s.expansion.parcel=true
			world.enter(world.area,world.pos)
			game.store()
			game.feedback("Three radish seeds and a lettuce seed. Your journal shows the first beds to try.")
		"Creek pottery":
			if Expansion.low_creek(model) and not model.s.expansion.finds.has("creek-pottery") and model.change("creek-pottery",1):
				Expansion.record(model,"creek-pottery","Willowbrook low bank")
				world.enter(world.area,world.pos)
				game.store()
				game.feedback("The willow pattern on this shard looks familiar.")
		"Forgotten passage":
			if world.area!="Mine" or int(model.s.mine.depth)!=9:return true
			if int(model.s.mine.lift)<9 or int(model.s.mine.cleared.get("9",0))<2:
				game.feedback("Reopen the level 9 lift and clear two deposits here to reach the river.")
			else:travel(game,"Below",Vector2(580,516))
		_:return false
	return true

static func sit(game,message:String):
	game.world.sitting=true
	var visitor:=""
	for person:String in game.world.npcs:
		var sprite:Sprite2D=game.world.npcs[person]
		if sprite.visible and sprite.position.distance_to(game.world.pos)<90:
			visitor=person
			break
	if visitor=="Oren":message+=" Oren says the creek sounds different here after rain."
	elif visitor=="Linn":message+=" Linn points out a leaf caught between the boards."
	game.feedback(message)

static func travel(game,region:String,at:Vector2):
	game.close_page()
	game.relocate(region,at,Vector2.DOWN)
	game.feedback(Routes.NAMES[region])

static func project(game,id:String,cost:Dictionary,page:String):
	if Expansion.complete_project(game.model,id,cost):
		game.world.enter(game.world.area,game.world.pos)
		game.store()
	else:game.feedback("Bring the materials listed on this page.")
	game.show_page(page)

static func home_note(game):
	var model=game.model
	var remaining:=21-int(model.s.day)%21
	var crop:Dictionary=model.crops[int(model.s.seed)]
	var next_event:=""
	for offset in range(1,23):
		var date:=int(model.s.day)+offset
		var season:=floori(date/21.0)%8
		if date%21==(6 if season==0 else 14):
			next_event="%s %d · %s"%[model.SEASONS[season],date%21+1,SeaSeason.TITLES[season]]
			break
	game.note("Tomorrow · "+model.weather(model.s.day+1))
	game.note("Next village event · "+next_event)
	var eligible:bool=model.season() in crop.seasons
	var next_season:=int(model.season()+1)%8
	var has_time:bool=int(crop.days)<remaining or next_season in crop.seasons
	game.note("%s · %d watered nights to maturity"%[crop.name,crop.days])
	if not eligible:game.note("Sow these seeds in "+model.SEASONS[crop.seasons[0]]+".")
	elif not has_time:game.note("If watered daily, this crop will mature after the next season starts.")
	else:game.note("These seeds have time to ripen if you water them daily.")

static func journal(game):
	var model=game.model
	var progress:Dictionary=model.s.expansion
	if progress.intro:
		if not progress.parcel:game.note("A seed parcel waits by the cottage door.")
		elif progress.lessons.size()<3:
			var labels:=["Turn an empty square with your hoe.","Sow radishes in the turned soil.","Water a planted square."]
			for i in range(3):
				game.note(("✓  " if progress.lessons.has(str(i)) else "◇  ")+labels[i])
		elif not progress.first_harvest:game.note("Check your radishes after two watered nights.")
		if int(model.s.day)>=1 and not progress.oren_note:
			game.note("Oren’s note · I check the crossing early, then fish on the farm bank until 14:09. If you’re late, try the village bridge lanterns or my lodge tomorrow.")
		if progress.first_harvest and not progress.linn_supper:
			game.note("Your first radish can go in the shipping bin, into your supper pot with mint, or to Linn as a gift.")
		if progress.linn_supper and not progress.linn_cooked:game.note("Meet Linn at Fern & Thistle House after 18:00 for supper.")
	if progress.intro and int(model.s.day)<7:
		if not model.s.tools.get("axe",false):game.note("Across the east bridge, Willowbrook Mercantile sells an axe for 18 crowns from 08:00.")
		elif not progress.projects.get("crafted-bench",false):game.note("Head north from Willowbrook. Chop an alder three times, then press C and build a garden bench for four wood.")
		if model.s.catches.is_empty():game.note("Along the farm creek, E at the lantern casts. Oren can give you a practice cast by the bank.")
	game.row("Bedside almanac",game.show_page.bind("Bedside almanac"))
	game.row("Field sketchbook",game.show_page.bind("Field sketchbook"))

static func cook_chowder(game,fish:String):
	var model=game.model
	var mint:="frogmint" if model.qty("frogmint")>0 else "herb"
	if model.qty(mint)<1 or model.qty(fish)<1 or not model.change("creek-soup",1):
		game.feedback("Bring a fish and a bundle of mint, and make room for the chowder.")
		return
	model.change(mint,-1)
	model.change(fish,-1)
	game.store()
	game.show_page("Hearth kitchen")
	game.feedback("The chowder is ready.")

static func cook_radish(game):
	var model=game.model
	if model.qty("p0")<1 or model.qty("herb")<1 or not model.change("soup",1):
		game.feedback("Bring a Breakfast radish and creek mint, and make room for the soup.")
		return
	model.change("p0",-1)
	model.change("herb",-1)
	game.store()
	game.show_page("Hearth kitchen")
	game.feedback("Your first harvest is ready for supper.")

static func linn_supper(game):
	var model=game.model
	if model.s.expansion.linn_cooked or not model.change("soup",2):return
	model.s.expansion.linn_cooked=true
	model.s.bonds.Linn=int(model.s.bonds.get("Linn",0))+2
	game.store()
	game.show_page("Linn’s supper")
	game.feedback("Linn sends you home with two portions of soup.")

static func collect_honey(game,kind:String):
	var model=game.model
	var progress:Dictionary=model.s.expansion
	var page:="Orchard hive" if kind=="orchard" else "Herb hive"
	if progress.hive!=kind:
		if progress.hive=="": 
			if model.qty("wood")<4:game.feedback("Bring four lengths of wood.");return
			model.change("wood",-4)
		progress.hive=kind
		progress.honey_day=int(model.s.day)+2
	elif int(model.s.day)>=int(progress.honey_day):
		var item:="blossom-honey" if kind=="orchard" else "herb-honey"
		if not model.change(item,1):game.feedback("Make room in your satchel.");return
		Expansion.record(model,item,"Hearthvale Farmlands")
		progress.honey_day=int(model.s.day)+2
	else:return
	game.store()
	game.show_page(page)

static func exhibit(game):
	var model=game.model
	if Expansion.complete_project(model,"archive",{"creek-pottery":1}):
		model.s.coins+=35
		game.world.enter(game.world.area,game.world.pos)
		game.store()
	game.show_page("Village archive")

static func set_shell(game):
	var model=game.model
	if model.s.expansion.shell_display or not model.change("tide-shell",-1):return
	model.s.expansion.shell_display=true
	if game.world.area=="Cottage":game.world.enter("Cottage",game.world.pos)
	game.store()
	game.show_page("Field sketchbook")

static func sell_stall(game,item:String):
	var model=game.model
	var progress:Dictionary=model.s.expansion
	if model.s.time<540 or model.s.time>=720:return
	if int(progress.stall_day)!=int(model.s.day):
		progress.stall_day=int(model.s.day)
		progress.stall_sales=[]
	if progress.stall_sales.size()>=3 or item in progress.stall_sales:return
	var price:int=model.value(item)
	if price<=0 or not model.change(item,-1):return
	model.s.coins+=price+maxi(2,price/3)
	var buyer:String=["Tavi","Ves","Nell"][progress.stall_sales.size()]
	progress.projects["last-sale-"+buyer]=item
	progress.projects["sale-date-"+buyer]=int(model.s.day)
	progress.projects["stall-buyer-"+str(progress.stall_sales.size())]=buyer
	progress.stall_sales.append(item)
	game.store()
	if game.world.area=="Village":game.show_market_customer(buyer,item,price+maxi(2,price/3))
	else:game.show_page("Player market stall")

static func greenhouse(game,plant:String):
	var model=game.model
	var projects:Dictionary=model.s.expansion.projects
	if not projects.get("greenhouse",false):return
	var key:String="planted-"+plant
	if not projects.has(key):
		if not model.change(plant,-1):return
		projects[key]=int(model.s.day)+3
	elif int(model.s.day)>=int(projects[key]) and model.change(plant,2):
		projects[key]=int(model.s.day)+3
	game.store()
	game.show_page("Greenhouse")

static func page(game,id:String)->bool:
	var model=game.model
	var progress:Dictionary=model.s.expansion
	var projects:Dictionary=progress.projects
	match id:
		"Bedside almanac":home_note(game)
		"Field sketchbook":
			if projects.has("steps-sketch"):
				game.sketch_entry("Sunshore · the old tide steps",game.world.tex["steps-wet"])
				game.note("Soren remembers a path here at low tide in Goldleaf and Emberfall.")
			if projects.has("shell-carving"):game.sketch_entry("The shell from the last step",game.world.tex["shell-carving"])
			if progress.finds.is_empty() and not projects.has("steps-sketch"):game.note("Your first catch or unusual find will leave a record here.")
			for key:String in progress.finds:
				var record:Dictionary=progress.finds[key]
				game.sketch_entry("%s · %s"%[model.item_name(key),record.place],game.farm_hud.product_icon(game,key))
				if Expansion.ITEMS.has(key):game.note(Expansion.ITEMS[key][2])
				var day:int=record.day
				game.note("%s %d · %s"%[model.SEASONS[floori(day/21.0)%8],day%21+1,record.weather])
			if model.qty("tide-shell")>0 and not progress.shell_display:game.row("Display a Sunshore shell on the cottage shelf",set_shell.bind(game))
		"Linn’s supper":
			if progress.linn_cooked:game.note("Linn tastes the broth, smiles, and wraps two bowls for your walk home.")
			else:
				game.note("Linn sets a radish on the board. You chop while she stirs a pot of herb broth.")
				game.row("Finish the soup with Linn",linn_supper.bind(game))
		"Lighthouse ferry":
			game.note("The tide pools are exposed." if Expansion.low_tide(model) else "The tide is covering the pools.")
			if projects.get("ferry",false):game.row("Sail to Moonpetal Isles",travel.bind(game,"Isles",Vector2(888,510)))
			else:game.row("Restore the ferry · 8 wood and 2 copper bars",project.bind(game,"ferry",{"wood":8,"copper-bar":2},id))
			if projects.get("greenhouse",false):game.note("The village cook will buy your coastal produce at the Willowbrook stall.")
		"Return ferry":game.row("Sail to Sunshore",travel.bind(game,"Coast",Vector2(873,482)))
		"Waterfall stair":
			game.note("The stair climbs beside the river. You can hear the falls above.")
			game.row("Open the stair to Silverwater Lakes",waterfall.bind(game))
		"Waterfall trail":
			game.note("Silver reeds grow below the falls. Look for their pale tips near the lower path.")
			if projects.get("waterfall",false):game.row("Descend the waterfall stair",travel.bind(game,"Below",Vector2(574,516)))
			if int(model.s.mine.dock_stage)>=4:game.row("Take Oren’s boat back to Willowbrook",travel.bind(game,"Village",Vector2(235,411)))
		"Elderwood ruins":game.note("Linn’s field note · The copper-colored caps here have short stems and ridged undersides.")
		"Frogwatch shelter":game.note("Listen for frogs after rain. Split-leaved frogmint grows close to their pools.")
		"Produce wagons":
			game.note("The traders follow the east road to the Emberglass oasis.")
			game.row("Ride back to Willowbrook",travel.bind(game,"Village",Vector2(1099,609)))
			if progress.visited.has("Desert"):game.row("Ride to the oasis",travel.bind(game,"Desert",Vector2(592,484)))
		"Oasis irrigation":
			if projects.get("oasis",false):
				game.note("Water runs through the restored channel. Glassbloom opens at 17:00.")
				game.row("Take the market wagon to Goldenreach",travel.bind(game,"Plains",Vector2(696,486)))
			else:game.row("Repair the channel · 6 stone and 2 wood",project.bind(game,"oasis",{"stone":6,"wood":2},id))
		"Quarry lift":
			game.note("The trail continues through pinewoods to Frostpine.")
			game.row("Ride down to Alderwood Grove",travel.bind(game,"Grove",Vector2(885,64)))
			if progress.visited.has("Frost"):game.row("Ride up to Frostpine",travel.bind(game,"Frost",Vector2(885,710)))
		"Geothermal shelter":
			game.note("A warm spring keeps the shelter and its winter sage alive through Starfrost.")
			game.row("Take the lift back to Ironpeak",travel.bind(game,"Highlands",Vector2(572,489)))
		"Greenhouse":
			if projects.get("greenhouse",false):
				game.note("Linn keeps the beds watered. Cuttings mature in three mornings in any season.")
				for plant in ["glassbloom","moon-fruit","winter-sage"]:
					var key:String="planted-"+plant
					if not projects.has(key):
						if model.qty(plant)>0:game.row("Plant "+model.item_name(plant),greenhouse.bind(game,plant))
					elif int(model.s.day)>=int(projects[key]):game.row("Pick two "+model.item_name(plant),greenhouse.bind(game,plant))
					else:game.note("%s · %d days until harvest"%[model.item_name(plant),int(projects[key])-int(model.s.day)])
			else:game.row("Restore the greenhouse · 8 wood and 4 stone",project.bind(game,"greenhouse",{"wood":8,"stone":4},id))
		"Herb hive","Orchard hive":
			var kind:="orchard" if id=="Orchard hive" else "herbs"
			game.note("The flowers around this hive give its honey a "+("blossom" if kind=="orchard" else "wild herb")+" scent.")
			if progress.hive=="":game.row("Build the hive · 4 wood",collect_honey.bind(game,kind))
			elif progress.hive!=kind:game.row("Move your hive here · honey in two mornings",collect_honey.bind(game,kind))
			elif int(model.s.day)>=int(progress.honey_day):game.row("Collect honey",collect_honey.bind(game,kind))
			else:game.note("Honey ready in %d mornings."%(int(progress.honey_day)-int(model.s.day)))
		"Village archive":
			if projects.get("archive",false):game.note("The restored shard sits beside Linn’s plate and a sketch of the mill that once stood here.")
			elif model.qty("creek-pottery")>0:game.row("Match the shard to Linn’s plate · 35 crowns",exhibit.bind(game))
			else:game.note("Linn is looking for pottery from the old mill. Look below the bridge when the creek runs low. The bank is "+("exposed today." if Expansion.low_creek(model) else "under water today."))
		"Player market stall":
			game.note("Set out up to three different products from 09:00 to noon.")
			if int(progress.stall_day)==int(model.s.day):
				for i in range(progress.stall_sales.size()):
					game.note("%s bought your %s."%[projects.get("stall-buyer-"+str(i),["Oren","A passing grower","Nell"][i]),model.item_name(progress.stall_sales[i])])
			if model.s.time>=540 and model.s.time<720:
				var sold:Array=progress.stall_sales if int(progress.stall_day)==int(model.s.day) else []
				if sold.size()<3:
					for item:String in model.s.bag:
						if model.value(item)>0 and item not in sold:
							game.row("Set out "+model.item_name(item),sell_stall.bind(game,item))
			else:game.note("Come back tomorrow morning." if model.s.time>=720 else "The stall opens at 09:00.")
		_:return false
	return true

static func waterfall(game):
	game.model.s.expansion.projects.waterfall=true
	travel(game,"Lakes",Vector2(540,476))

