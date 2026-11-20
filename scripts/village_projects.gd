extends RefCounted

const Life=preload("res://scripts/world_life.gd")
const Expansion=preload("res://scripts/expansion.gd")
const Rooms=preload("res://scripts/arcade_rooms.gd")
const Market:="Willowbrook market supper"
const Orchard:="Old south orchard"
const Bridge:="Alderwood footbridge"
const Walk:="Linn’s dawn walk"
const Work:="Village commissions"
const MarketSpot:=Vector2(795,420)
const HerbClearing:=Vector2(685,556)
const FarmBridge:=Vector2(721,649)
const GroveBridge:=Vector2(714,693)
const Crops:={"grow":"Grow radishes for Pip","fish":"Catch a fish for Oren","build":"Bring timber or copper for Ves"}
const Artwork:=["apple","pear","picnic","bridge","lantern","supper","preserves","quarry","herbs","reeds","ice","arch"]
const FieldNotes:=[
	["Grove","First alder buds",Vector2(562,634),"cone"],
	["Village","Blossom picnic",Vector2(796,489),"herb"],
	["Lakes","Suncrest water lilies",Vector2(650,467),"lake-reed"],
	["Marsh","Raincall boardwalk",Vector2(793,504),"frogmint"],
	["Coast","Goldleaf shell bank",Vector2(721,508),"tide-shell"],
	["Forest","Emberfall mushroom ring",Vector2(515,540),"woodland-cap"],
	["Frost","Snowrest ice crossing",Vector2(665,520),"winter-sage"],
	["Highlands","Starfrost quartz ledge",Vector2(720,535),"highland-quartz"]
]

static func data(model)->Dictionary:
	return model.s.expansion.projects

static func load_art(world):
	for name:String in Artwork:
		world.tex["project-"+name]=load("res://assets/projects/"+name+".png")

static func decorate(world):
	var p:=data(world.model)
	match world.area:
		"Farm":
			world.spot(Orchard,"project-apple",Vector2(380,651),.82,Vector2(19,12))
			if not p.get("orchard-cleared",false):
				for x in [410,452,510]:world.prop("hearth-logs",Vector2(x,638+x%25),.58)
			Rooms.place_sign(world,Vector2(371,690),"South orchard")
			world.spot(Bridge,"project-bridge" if p.get("south-bridge",false) else "hearth-logs",FarmBridge,.83)
			Rooms.place_sign(world,FarmBridge+Vector2(39,14),"Alderwood","↑")
			var style:String=p.get("orchard-plan","")
			if style!="":
				var mature:bool=int(world.model.s.day)>=int(p["orchard-ready"])
				for i in (2 if style=="picnic" else 3):
					var center:=Vector2(426+i*51,648+i%2*15)
					world.prop("project-pear" if style=="pear" else "project-apple",center,.68 if mature else .36)
					world.barriers.append(Rect2(center-Vector2(8,8),Vector2(16,10)))
				if mature and style=="picnic":world.prop("project-picnic",Vector2(476,687),.69)
			for i in 4:world.ground_detail("stepping-stones",Vector2(405+i*63,689-i%2*4),.45)
		"Grove":
			if p.get("south-bridge",false):world.spot(Bridge,"project-bridge",GroveBridge,.83)
		"Village":
			var meal:bool=p.get("market-keepsake","")=="grow" or (is_market(world.model) and p.get("market-delivery","")=="grow")
			var lit:bool=p.get("market-keepsake","")=="build" or (is_market(world.model) and p.get("market-delivery","")=="build")
			var at:=MarketSpot
			world.spot(Market,"project-supper" if meal else "market",at,.69,Vector2(40,15))
			if lit:world.prop("project-lantern",at+Vector2(-36,2),.93)
			if (p.get("market-keepsake","")=="fish" or (is_market(world.model) and p.get("market-delivery","")=="fish")) and world.tex.has("catch-"+str(p.get("market-item","perch"))):
				world.prop("catch-"+str(p.get("market-item","perch")),at+Vector2(9,-6),.68)
		"Bakery":
			world.spot(Work,"project-preserves",Vector2(518,376),.53)
		"Forest":
			if p.has("linn-walk"):
				var stage:=int(p["linn-walk"])
				var at:=Vector2(662,523) if stage==1 else HerbClearing
				world.spot(Walk,"project-herbs",at,.77)
				if stage<3 or int(world.model.s.day)>=int(p["linn-ready"]):
					var linn:=Sprite2D.new()
					linn.texture=world.work_poses["Linn"]
					linn.hframes=3
					linn.frame=2 if stage<3 else 0
					linn.position=at+Vector2(-16,5)
					linn.offset=Vector2(0,-21)
					world.actors.add_child(linn)
			world.spot("Return across Raincall boardwalk","project-reeds",Vector2(714,553),.68)
		"Highlands":
			world.spot("Return across Snowrest ice","project-ice",Vector2(714,553),.68)
		"Mine":
			var depth:=int(world.model.s.mine.depth)
			if depth==3:world.spot("Slate quarry spur","project-quarry",Vector2(369,480),.72)
			if depth>=7:world.spot("Flooded side chamber","project-arch",Vector2(789,405),.68)
		"SlateSpur","FloodedSpur":
			side_chamber(world)
	for index in FieldNotes.size():
		var find:Array=FieldNotes[index]
		if world.area!=find[0]:continue
		world.spot(find[1],"project-reeds" if index==3 else ("project-ice" if index==6 else "project-herbs"),find[2],.55)
		if index in [3,6]:Rooms.place_sign(world,find[2]+Vector2(35,2),find[1])

static func side_chamber(world):
	var wet:bool=world.area=="FloodedSpur"
	world.ground_detail("mine-floor-2" if wet else "mine-floor-0",Vector2(576,356),1.0)
	world.prop("project-arch",Vector2(574,267),.86)
	world.spot("Return to mine","dock-lantern",Vector2(576,508),.77)
	if wet:
		world.barriers.append(Rect2(705,283,143,49))
		world.spot("Lantern pool","mine-dock",Vector2(736,354),.73)
		for at in [Vector2(395,315),Vector2(673,315),Vector2(803,315),Vector2(820,425),Vector2(348,452)]:
			world.prop("mine-crystal",at,.67+float(int(at.x)%3)*.12)
		for at in [Vector2(361,382),Vector2(659,408),Vector2(801,470)]:
			world.prop("mine-mushrooms",at,.65)
	else:
		for x in [389,612,760]:
			world.spot("Slate seam "+str(x),"project-quarry",Vector2(x,375),.82,Vector2(26,14))

static func is_market(model)->bool:
	return int(model.s.day)%7==6 and model.s.time>=540 and model.s.time<1140

static func handle(game,id:String)->bool:
	var m=game.model
	var w=game.world
	var p:=data(m)
	match id:
		Market:
			game.show_page(Market)
		Bridge:
			if not p.get("south-bridge",false):game.show_page(Bridge)
			else:
				var to_farm:bool=w.area=="Grove"
				travel(game,"Farm" if to_farm else "Grove",(FarmBridge if to_farm else GroveBridge)+Vector2(0,-22))
		Orchard,Walk,Work:
			game.show_page(id)
		"Slate quarry spur","Flooded side chamber":
			var depth:=int(m.s.mine.depth)
			if int(m.s.mine.cleared.get(str(depth),0))<1:
				game.feedback("Clear one deposit on this floor to reach the side passage.")
			else:travel(game,"SlateSpur" if id=="Slate quarry spur" else "FloodedSpur",Vector2(576,478))
		"Return to mine":
			travel(game,"Mine",Vector2(578,486))
		"Return across Raincall boardwalk","Return across Snowrest ice":
			var index:=3 if id.contains("Raincall") else 6
			if m.season()!=index:game.feedback("This crossing opens in "+m.SEASONS[index]+".")
			else:travel(game,FieldNotes[index][0],FieldNotes[index][2]+Vector2(0,27))
		"Lantern pool":
			game.start_fishing("mine")
		_:
			if id.begins_with("Slate seam "):
				var key:="spur-"+id
				if int(p.get(key,-1))==int(m.s.day):game.feedback("That seam is spent until tomorrow.")
				elif m.change("stone",3):
					p[key]=int(m.s.day)
					game.store()
					game.feedback("Cut three pieces of slate for stone paths.")
				return true
			for index in FieldNotes.size():
				if FieldNotes[index][1]==id:
					field_find(game,index)
					return true
			return false
	return true

static func travel(game,area:String,at:Vector2):
	game.close_page()
	game.relocate(area,at,Vector2.UP)

static func field_find(game,index:int):
	var m=game.model
	var p:=data(m)
	var find:Array=FieldNotes[index]
	if index in [3,6] and m.season()==index and game.world.area==find[0]:
		if int(p.get(find[1],-1))!=int(m.s.day) and m.change(find[3],1):
			p[find[1]]=int(m.s.day)
			p["discovery-"+str(index)]=true
		game.world.sitting=false
		travel(game,"Forest" if index==3 else "Highlands",Vector2(714,574))
		game.feedback("The seasonal crossing leads to "+game.Routes.NAMES[game.world.area]+".")
		return
	if m.season()!=index:
		game.feedback("Return during "+m.SEASONS[index]+".")
	elif int(p.get(find[1],-1))==int(m.s.day):
		game.feedback("You’ve sketched this spot today.")
	elif m.change(find[3],1):
		p[find[1]]=int(m.s.day)
		p["discovery-"+str(index)]=true
		game.store()
		game.feedback("Sketched "+find[1]+" and collected "+m.item_name(find[3])+".")

static func hint(game):
	var p:=data(game.model)
	if not p.has("market-keepsake"):
		game.note("Iona is planning a supper at the Willowbrook market. Bring a contribution any day. The market opens on day seven of each week at 09:00.")
	game.row("Market supper",game.show_page.bind(Market))
	game.row("Restoration and seasonal notes",game.show_page.bind("Restoration notes"))

static func page(game,id:String)->bool:
	var m=game.model
	var p:=data(m)
	match id:
		Market:
			market_page(game,p)
		Bridge:
			game.sketch_entry("A footbridge from the farm to Alderwood",game.world.tex["project-bridge"])
			game.note("The bridge cuts out the trip through Willowbrook. Bring eight wood and three stone.")
			if game.world.area=="Farm":game.row("Restore the footbridge",build_bridge.bind(game))
		Orchard:
			orchard_page(game,p)
		Walk:
			walk_page(game,p)
		Work:
			work_page(game)
		"Restoration notes":
			game.note("Build the Alderwood footbridge near the south farm fence. Restore the old orchard west of it.")
			game.note("Bring tools to the slate spur on mine level 3 or a rod to the side pool from level 7.")
			for index in FieldNotes.size():
				var find:Array=FieldNotes[index]
				game.note("%s · %s · %s%s"%[m.SEASONS[index],game.Routes.NAMES[find[0]],find[1]," ✓" if p.has("discovery-"+str(index)) else ""])
		_:
			return false
	return true

static func market_page(game,p:Dictionary):
	var m=game.model
	var path:String=p.get("market-choice","")
	var delivery:String=p.get("market-delivery","")
	game.sketch_entry("Iona’s invitation",game.world.tex["project-supper"])
	if p.has("market-keepsake"):
		game.note({"grow":"Pip still serves your radish supper at the market.","fish":"Nell still talks about the fish you landed for her stall.","build":"The lantern you helped Ves repair lights the square."}[p["market-keepsake"]])
		game.note({"grow":"Next, graft the south orchard for fruit to preserve.","fish":"Next, try the Copper Kettle’s daily fish commission or explore the side pool on mine level seven.","build":"Next, restore the Alderwood footbridge at the south farm fence."}[p["market-keepsake"]])
		game.row("Village commissions",game.show_page.bind(Work))
	elif delivery!="":
		game.note("Your contribution is ready. Visit the market on day seven of any week from 09:00 to 19:00.")
		if game.world.area=="Village" and game.world.pos.distance_to(MarketSpot)<75 and is_market(m):
			game.row("Join the market supper",finish_market.bind(game,delivery))
	else:
		game.note("Bring two radishes, a fish you caught, or four wood or one copper. Iona will hold your contribution for the next market.")
		for key:String in Crops:
			game.row(("✓ " if path==key else "")+Crops[key],choose_market.bind(game,key))
		if game.world.area not in ["Village","Mercantile","Bakery"]:return
		if game.world.area=="Village" and game.world.pos.distance_to(MarketSpot)>=75 and game.speaker.get("id","")!="Iona":
			game.note("Deliver your contribution at the supper stall near the square.")
			return
		match path:
			"grow":
				if m.qty("p0")>=2:game.row("Deliver two radishes",submit_market.bind(game,path,"p0",2))
			"fish":
				for fish:Dictionary in Life.FISH:
					if m.qty(fish.id)>0 and m.s.catches.has(fish.id):game.row("Deliver "+fish.name,submit_market.bind(game,path,fish.id,1))
			"build":
				if m.qty("wood")>=4:game.row("Deliver four wood",submit_market.bind(game,path,"wood",4))
				if m.qty("copper")>=1:game.row("Deliver one copper",submit_market.bind(game,path,"copper",1))

static func choose_market(game,path:String):
	data(game.model)["market-choice"]=path
	game.store()
	game.show_page(Market)

static func submit_market(game,path:String,item:String,count:int):
	var p:=data(game.model)
	if p.has("market-delivery") or not game.model.change(item,-count):return
	p["market-delivery"]=path
	p["market-item"]=item
	game.store()
	game.show_page(Market)

static func finish_market(game,path:String):
	var p:=data(game.model)
	if p.has("market-keepsake") or p.get("market-delivery","")!=path or not is_market(game.model):return
	p["market-keepsake"]=path
	game.model.s.coins+=45
	game.world.enter("Village",game.world.pos)
	game.store()
	game.close_page()
	game.feedback({"grow":"Pip serves your radish supper. Iona pays you 45 crowns.","fish":"Nell buys your %s for the supper. You earn 45 crowns."%game.model.item_name(p["market-item"]),"build":"Ves lights your restored market lantern. You earn 45 crowns."}[path])

static func build_bridge(game):
	if not Expansion.complete_project(game.model,"south-bridge",{"wood":8,"stone":3}):
		game.note("Bring both materials to the south fence.")
		return
	game.world.enter("Farm",game.world.pos)
	game.store()
	game.close_page()
	game.feedback("The footbridge is open. You can cross in either direction.")


static func orchard_page(game,p:Dictionary):
	var m=game.model
	game.sketch_entry("The old orchard",game.world.tex["project-apple"])
	if not p.get("orchard-cleared",false):
		game.note("Clear the fallen limbs around the old trees. Cut them down with an equipped axe and keep the timber.")
		game.row("Clear fallen branches",clear_orchard.bind(game))
	elif not p.has("orchard-plan"):
		game.note("Choose what to keep. Any plan costs four wood and takes seven mornings to settle.")
		for choice:Array in [["apple","Keep the old apples"],["pear","Graft a row of golden pears"],["picnic","Keep two apple trees and make room for a picnic"]]:
			game.row(choice[1],plant_orchard.bind(game,choice[0]))
	elif int(m.s.day)<int(p["orchard-ready"]):
		game.note("New growth in %d mornings."%(int(p["orchard-ready"])-int(m.s.day)))
	else:
		game.note({"apple":"The old apples have taken on fresh growth.","pear":"The golden pears are growing along the fence.","picnic":"Leave a basket here and listen to the branches overhead."}[p["orchard-plan"]])
		if int(m.s.day)>=int(p.get("orchard-harvest",0)):
			game.row("Gather three ripe fruit",harvest_orchard.bind(game))
		if p["orchard-plan"]=="picnic":game.row("Sit for a picnic",picnic.bind(game))
		if m.qty("orchard-apple")>=2:game.row("Make apple preserves",jar_fruit.bind(game,"orchard-apple"))
		if m.qty("orchard-pear")>=2:game.row("Make pear preserves",jar_fruit.bind(game,"orchard-pear"))

static func clear_orchard(game):
	var m=game.model
	if not m.s.tools.get("axe",false):
		game.note("Buy an axe at the Mercantile first.")
		return
	if data(m).has("orchard-cleared") or not m.change("wood",4):return
	data(m)["orchard-cleared"]=true
	refresh(game,Orchard)

static func plant_orchard(game,choice:String):
	var m=game.model
	if data(m).has("orchard-plan") or not m.change("wood",-4):
		game.note("Bring four wood to stake and protect the trees.")
		return
	data(m)["orchard-plan"]=choice
	data(m)["orchard-ready"]=int(m.s.day)+7
	refresh(game,Orchard)

static func harvest_orchard(game):
	var m=game.model
	var p:=data(m)
	if int(m.s.day)<maxi(int(p["orchard-ready"]),int(p.get("orchard-harvest",0))):return
	if m.change("orchard-pear" if p["orchard-plan"]=="pear" else "orchard-apple",3):
		p["orchard-harvest"]=int(m.s.day)+3
		refresh(game,Orchard)

static func picnic(game):
	game.close_page()
	game.world.sitting=true
	game.feedback("The orchard is quiet except for wind in the branches.")

static func jar_fruit(game,item:String):
	var m=game.model
	if m.qty(item)>=2 and m.change("orchard-jar",1):
		m.change(item,-2)
		refresh(game,Orchard)

static func refresh(game,id:String):
	game.world.enter(game.world.area,game.world.pos)
	game.store()
	game.show_page(id)

static func walk_page(game,p:Dictionary):
	var m=game.model
	var stage:=int(p.get("linn-walk",0))
	if stage==0:
		game.note("Once you’ve filled Linn’s herbarium request, she’ll show you a sheltered patch in Elderwood.")
		if m.s.requests.get("Linn","")=="done":game.row("Accept Linn’s invitation",walk_step.bind(game,1))
	elif stage==1:
		game.note("Meet Linn near the Elderwood ruins before 10:00. She’ll come any morning.")
		if game.world.area=="Forest" and m.s.time<600:game.row("Take the trail with Linn",walk_step.bind(game,2))
	elif stage==2:
		if game.world.area!="Forest" or game.world.pos.distance_to(HerbClearing)>65:
			game.note("Follow Linn toward the clearing just southeast of the ruins.")
			return
		game.note("Linn parts the branches. ‘This hollow holds rain. The rise gets the first light. Where would you plant?’")
		for choice:String in ["sheltered hollow","sunny rise"]:
			game.row("Plant on the "+choice,plant_herbs.bind(game,choice))
	else:
		game.note("You planted the "+p["linn-plot"]+". Return after twenty-one mornings.")
		if int(m.s.day)>=int(p["linn-ready"]) and int(p.get("linn-harvest",-1))!=int(m.s.day):
			game.row("Gather herbs with Linn",harvest_herbs.bind(game))

static func walk_step(game,step:int):
	data(game.model)["linn-walk"]=step
	if step==2:
		game.world.enter("Forest",game.world.pos)
		game.store()
		game.close_page()
		game.feedback("Linn heads southeast toward the clearing. Follow her down the trail.")
	else:
		game.store()
		game.show_page(Walk)

static func plant_herbs(game,choice:String):
	var p:=data(game.model)
	p["linn-walk"]=3
	p["linn-plot"]=choice
	p["linn-ready"]=int(game.model.s.day)+21
	game.model.s.bonds["Linn"]=int(game.model.s.bonds.get("Linn",0))+2
	refresh(game,Walk)

static func harvest_herbs(game):
	var m=game.model
	var p:=data(m)
	if int(m.s.day)<int(p["linn-ready"]) or int(p.get("linn-harvest",-1))==int(m.s.day):return
	if m.change("frogmint" if p["linn-plot"]=="sheltered hollow" else "herb",3):
		p["linn-harvest"]=int(m.s.day)
		game.store()
		game.close_page()
		game.feedback("Linn takes a sprig for her book and leaves three bundles with you.")

static func work_page(game):
	var m=game.model
	var p:=data(m)
	game.note("Sell preserves to Pip, supply fresh fish for the Copper Kettle, or fill Ves’s building orders. Each trade pays once per day.")
	if game.world.area!="Bakery" or game.world.pos.distance_to(Vector2(518,376))>=75:
		game.note("Take your goods to the commission counter inside the Copper Kettle.")
		return
	for job:Array in [["orchard-jar",1,56,"A jar of orchard preserves"],["stone",4,29,"Four stone for path repairs"],["wood",4,24,"Four wood for new shelves"]]:
		commission_row(game,job[0],job[1],job[2],job[3])
	if int(p.get("commission-fish",-1))!=int(m.s.day):
		for fish:Dictionary in Life.FISH:
			if m.qty(fish.id)>0:commission_row(game,fish.id,1,int(fish.price)+10,m.item_name(fish.id),"fish")

static func commission_row(game,item:String,count:int,pay:int,label:String,category:String=""):
	var m=game.model
	var key:="commission-"+(category if category!="" else item)
	if m.qty(item)>=count and int(data(m).get(key,-1))!=int(m.s.day):
		game.row("%s · %d crowns"%[label,pay],sell_commission.bind(game,item,count,pay,key))

static func sell_commission(game,item:String,count:int,pay:int,key:String):
	var m=game.model
	if int(data(m).get(key,-1))==int(m.s.day) or not m.change(item,-count):return
	data(m)[key]=int(m.s.day)
	m.s.coins+=pay
	game.store()
	game.show_page(Work)


static func market_memory(model,resident:String)->String:
	var path:String=data(model).get("market-keepsake","")
	match resident:
		"Pip":
			if path=="grow":return "Your radishes went into the first pot. I still make that supper on market day."
		"Nell":
			if path=="fish":return "I still remember the fish you caught for our supper. Bring another to the Copper Kettle sometime."
		"Ves":
			if path=="build":return "I pass under your lantern on my way home. It makes the whole square look warmer."
	return ""
