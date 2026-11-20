extends RefCounted

const Routes=preload("res://scripts/world_routes.gd")
const Mine=preload("res://scripts/mine_progress.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
const Expansion=preload("res://scripts/expansion.gd")
const Life=preload("res://scripts/world_life.gd")

const SEASONS = ["Seedwake","Bloomrise","Suncrest","Raincall","Goldleaf","Emberfall","Snowrest","Starfrost"]
const WEATHER = ["Fair","Breezy","Showers","Showers","Fair","Mist","Snow","Aurora"]
const CAPACITY = 999
var home=preload("res://scripts/homestead.gd").new()
var crops: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
var s: Dictionary
var village:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/village.json"))
var workshop:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop.json"))
var recovering:=false
var slot := 1

func _init():
	for crop in crops:
		crop.seasons=Array(crop.seasons).map(func(v): return int(v))
	reset()

func reset():
	recovering=false
	s = {"version":1,"farmer_name":"Rowan","pronouns":"they/them","look":0,"day":0,"time":360.0,"coins":24,"area":"Farm","x":365.0,"y":346.0,"seed":0,"bag":{"s0":5,"s1":2},"chest":{},"soil":{},"shipping":0,"sold":0,"harvests":0,"completed_orders":{},"upgrades":{},"harvest_book":{},"packet_period":-1,"batch":{},"quest":0,"visits":{},"bonds":{},"speed":1.0,"sound":true,"hen":false,"fed":-1,"decor":{},"catches":{},"fish_records":{},"fishing_xp":0,"resources":{},"tools":{"rod":true},"requests":{},"gifts":{},"moods":{},"friend_events":{},"arcade_sales":{},"arcade_day":-1,"furnishings":{},"compost_charges":0,"egg_day":-1,"picked":{},"season_events":{},"mine":Mine.defaults(),"expansion":Expansion.defaults()}

func season() -> int:
	return floori(float(s.day)/21.0)%8

func is_fair()->bool:
	return int(s.day)%168==6

func weather(day:int) -> String:
	var period := floori(day/21.0)%8
	if day==0: return "Fair"
	return WEATHER[period] if (day*17+period)%5<3 else ["Fair","Breezy","Showers"][(day*13+period)%3]

func qty(id:String) -> int:
	return int(s.bag.get(id,0))

func item_name(id:String) -> String:
	if Expansion.ITEMS.has(id):return Expansion.ITEMS[id][0]
	if Mine.NAMES.has(id):return Mine.NAMES[id]
	if id.begins_with("jar"):return crops[int(id.substr(3))].name+" preserves"
	if id.left(1) in ["s","p"] and id.substr(1).is_valid_int():
		return crops[int(id.substr(1))].name + (" seeds" if id.begins_with("s") else "")
	if village.foods.has(id):return village.foods[id].name
	if workshop.has(id):return workshop[id].name
	if id=="wood":return "Fallen wood"
	if Life.RESOURCE_NAMES.has(id):return Life.RESOURCE_NAMES[id]
	if id=="bait":return "Creek bait"
	if id=="compost":return "Leaf compost"
	if Stock.FURNISHINGS.has(id):return Stock.FURNISHINGS[id]
	for species in Life.FISH:
		if id==species.id:return species.name
	return {"egg":"Speckled egg","herb":"Creek mint","tea":"Mint tea","soup":"Garden soup"}.get(id,id)

func change(id:String,n:int) -> bool:
	var total := qty(id)+n
	if total<0 or total>CAPACITY: return false
	if total==0: s.bag.erase(id)
	else: s.bag[id]=total
	return true

func buy(index:int) -> bool:
	if index<0 or index>=crops.size(): return false
	var c:Dictionary=crops[index]
	if s.coins<c.cost or not change("s"+str(index),1): return false
	s.coins-=int(c.cost)
	return true

func work(tile:String,action:int) -> String:
	var p:Dictionary=s.soil.get(tile,{})
	if action==0:
		if not p.is_empty(): return "This bed is already turned."
		s.soil[tile]={"crop":-1,"age":0,"wet":weather(s.day)=="Showers" or s.tools.get("sprinkler",false)}
		return "Soil turned. Choose seeds with 2."
	if p.is_empty(): return "Turn the soil with the hoe first."
	if action==1:
		var i:int=s.seed
		if p.crop>=0: return "There is already a crop here."
		if not season() in crops[i].seasons: return "Plant this crop in "+SEASONS[crops[i].seasons[0]]+"."
		if not change("s"+str(i),-1): return "Out of seeds. Visit the green market stall."
		p.crop=i
		p.age=1 if int(s.compost_charges)>0 else 0
		if int(s.compost_charges)>0:s.compost_charges-=1
		return "Planted "+crops[i].name+"."
	if action==2:
		p.wet=true
		return "Watered. Growth happens overnight."
	if p.crop<0: return "An empty seedbed."
	var c:Dictionary=crops[int(p.crop)]
	if p.age<c.days: return "%s • %d of %d growing days" % [c.name,p.age,c.days]
	if not change("p"+str(int(p.crop)),int(c.yield_count)): return "Your bag is full."
	home.record_harvest(self,int(p.crop))
	s.harvests+=int(c.yield_count)
	p.crop=-1
	p.age=0
	return "Harvested "+c.name+"!"

func install_equipment(id:String):
	s.tools[id]=true
	if id=="sprinkler":
		for plot:Dictionary in s.soil.values():plot.wet=true

func overnight():
	for cell:String in s.soil:
		var p:Dictionary=s.soil[cell]
		if p.wet and p.crop>=0: p.age+=1
		p.wet=weather(s.day+1)=="Showers" or (s.upgrades.has("cistern") and cell.ends_with(",0")) or s.tools.get("sprinkler",false)
	s.coins+=s.shipping
	s.shipping=0
	if s.fed==s.day: s.egg_day=s.day+1
	s.day+=1
	s.time=360.0
	s.mine.energy=100.0
	s.mine.fuel_until=-1.0

func value(id:String) -> int:
	if Expansion.ITEMS.has(id):return Expansion.ITEMS[id][1]
	if Mine.PRICES.has(id):return Mine.PRICES[id]
	if id.begins_with("jar"):return int(crops[int(id.substr(3))].price)*4+8
	if id.begins_with("p") and id.substr(1).is_valid_int(): return int(crops[int(id.substr(1))].price)
	if village.foods.has(id):return int(village.foods[id].price)
	for species in Life.FISH:
		if id==species.id:return int(species.price)
	return {"wood":2,"stone":3,"copper":13,"cone":2,"bait":1,"herb":3,"tea":9,"egg":7,"soup":22}.get(id,0)

func ship(id:String) -> bool:
	var price:=value(id)
	if price<=0 or not change(id,-1): return false
	s.shipping+=price
	s.sold+=1
	return true

func transfer(id:String,deposit:bool) -> bool:
	var count:=int(s.chest.get(id,0))
	if deposit:
		if count>=CAPACITY or not change(id,-1): return false
		s.chest[id]=count+1
	else:
		if count<1 or not change(id,1): return false
		if count==1:s.chest.erase(id)
		else:s.chest[id]=count-1
	return true

func craft(id:String)->bool:
	if not workshop.has(id) or qty(id)>=CAPACITY:return false
	var material:String=workshop[id].get("material","wood")
	if not change(material,-int(workshop[id].get("count",workshop[id].get("wood",0)))):return false
	return change(id,1)
func cook(recipe:String) -> bool:
	var inputs:Dictionary=village.recipes.get(recipe,{})
	if inputs.is_empty() or qty(recipe)>=CAPACITY: return false
	for k in inputs:
		if qty(k)<inputs[k]: return false
	for k in inputs: change(k,-int(inputs[k]))
	change(recipe,1)
	return true

func record_visit(person:String):
	if s.visits.get(person,-1)!=s.day:
		s.visits[person]=s.day
		s.bonds[person]=int(s.bonds.get(person,0))+1

func talk(person:String) -> String:
	record_visit(person)
	if person==village.quest.giver:
		if s.quest==0:
			s.quest=1
			return "When you pull your first radish, bring one by. I want to taste this year's soil."
		if s.quest==1 and change(village.quest.item,-1):
			s.quest=2
			s.coins+=int(village.quest.reward)
			return "Peppery already! Here, thirty crowns. Your gran always insisted I pay market price."
	for resident in village.residents:
		if resident.id==person:return resident.greetings[int(s.day)%resident.greetings.size()]
	return "See you at the bridge."

func path_for() -> String:
	return "user://farm_%d.json"%slot

func save_game() -> bool:
	var path:=path_for()
	var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not f: return false
	f.store_string(JSON.stringify(s))
	f.flush()
	var err:=f.get_error()
	f.close()
	if err!=OK: return false
	if FileAccess.file_exists(path) and not recovering:
		if DirAccess.copy_absolute(path,path+".bak")!=OK: return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:return false
	recovering=false
	return true

func load_game() -> bool:
	for path in [path_for(),path_for()+".bak"]:
		if not FileAccess.file_exists(path): continue
		var parser:=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path))!=OK: continue
		var v=parser.data
		if not v is Dictionary or v.get("version")!=1: continue
		var valid:=true
		for key in ["soil","bag","chest","visits","bonds","picked"]:
			if not v.get(key) is Dictionary: valid=false
		if not valid or not v.get("day") is float or not Routes.NAMES.has(v.get("area")):continue
		if int(v.get("seed",0)) not in range(crops.size()) or int(v.get("quest",0)) not in range(3):continue
		for plot in v.soil.values():
			if not plot is Dictionary or int(plot.get("crop",-2)) < -1 or int(plot.get("crop",-2))>=crops.size() or not plot.has("age") or not plot.has("wet"):valid=false
		for key in ["resources","tools","requests","gifts","moods","fish_records","friend_events","arcade_sales","furnishings","season_events"]:
			if v.has(key) and not v[key] is Dictionary:valid=false
		if v.get("mine",{}) is Dictionary:
			for key in ["nodes","cleared","beaten"]:
				if v.get("mine",{}).has(key) and not v.mine[key] is Dictionary:valid=false
		else:valid=false
		if not valid:continue
		reset()
		recovering=path.ends_with(".bak")
		s.merge(v,true)
		var mine_defaults:=Mine.defaults()
		if s.mine is Dictionary:mine_defaults.merge(s.mine,true)
		s.mine=mine_defaults
		var expansion_defaults:=Expansion.defaults()
		if s.expansion is Dictionary:expansion_defaults.merge(s.expansion,true)
		s.expansion=expansion_defaults
		s.mine.depth=clampi(int(s.mine.depth),1,Mine.DEPTHS)
		s.day=int(s.day)
		s.seed=int(s.seed)
		if s.tools.get("sprinkler",false):install_equipment("sprinkler")
		# The old village guesthouse used the same room ID as the farmhouse.
		if s.area=="Cottage" and s.get("door","Farm")=="Village":
			s.area="Bakery"
			s.x=576.0
			s.y=480.0
		return true
	return false

