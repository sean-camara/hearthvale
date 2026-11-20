extends RefCounted

const Life=preload("res://scripts/world_life.gd")
const FURNISHINGS:={"home-rug":"Botanical rug","home-seat":"Oak reading seat","home-lamp":"Bedside lamp","home-cabinet":"China cupboard","home-wall":"Sage wall covering"}
const HOURS:=Vector2i(540,1140)
const STORES:={
	"Farm Supply":{"keeper":"Iona","at":Vector2(389,325),"art":"general-counter","catalog":[
		["s0","Breakfast radish seeds",4,12,6,"Four quick-growing seeds for Seedwake.",false],
		["s1","Butter lettuce seeds",4,16,5,"Four lettuce seeds for the spring garden.",false],
		["compost","Leaf compost",1,11,8,"Use the satchel to charge your next six plantings. Each starts one growth day ahead.",false],
		["sprinkler","Field sprinkler",1,100,1,"Installed on your farm. Waters every prepared field bed when installed and each morning.",true],
		["long-can","Long-spout can",1,72,1,"Equipment upgrade. Water prepared beds from farther away.",true],
		["broad-hoe","Broad hoe",1,68,1,"Equipment upgrade. Reach farther across the seedbeds when tilling.",true],
	]},
	"Tackle Shop":{"keeper":"Oren","at":Vector2(575,325),"art":"general-counter","catalog":[
		["bait","Creek bait",3,10,8,"Three tins. One tin is used per cast.",false],
		["rod-upgrade","River reel",1,Life.TOOLS["rod-upgrade"][1],1,"A wider catch zone at the creek or pond.",true],
	]},
	"Flowers & Garden":{"keeper":"Linn","at":Vector2(762,325),"art":"herb-table","catalog":[
		["garden-pot","Flower planter",1,24,5,"Place a flowering planter on clear farm lawn from the Workshop.",false],
		["fence","Split-rail fence",1,9,10,"Place a fence segment anywhere suitable on your farm.",false],
		["lantern","Orchard lantern",1,18,6,"A warm garden lamp you can place from the Workshop.",false],
	]},
	"Tool & Hardware":{"keeper":"Ves","at":Vector2(389,433),"art":"general-counter","catalog":[
		["axe","Axe",1,Life.TOOLS.axe[1],1,"Harvest wood from the grove’s trees.",true],
		["pickaxe","Pickaxe",1,Life.TOOLS.pickaxe[1],1,"Break fieldstone and mine copper.",true],
		["wood","Wood bundle",5,25,7,"Five lengths of wood for crafting and orders.",false],
		["stone","Fieldstone",3,18,6,"Three pieces of stone for workshop orders.",false],
	]},
	"Furniture & Home":{"keeper":"Mara","at":Vector2(575,433),"art":"herb-table","catalog":[
		["home-rug","Botanical rug",1,29,4,"Use from the satchel to change your cottage’s sitting-room rug.",false],
		["home-seat","Oak reading seat",1,42,3,"Use from the satchel to furnish the cottage beside the window.",false],
		["home-lamp","Bedside lamp",1,26,4,"Install a lit oak side table near the cottage door.",false],
		["home-cabinet","China cupboard",1,49,3,"Install a glass cabinet along the hearth wall in your cottage.",false],
		["home-wall","Sage wall covering",1,39,4,"Hang leaf-patterned sage paper on your cottage’s rear wall.",false],
		["bench","Garden bench",1,28,4,"A wooden bench to place on your farm from the Workshop.",false],
	]},
	"General Goods":{"keeper":"Nell","at":Vector2(762,433),"art":"pastry-counter","catalog":[
		["tea","Mint tea",1,12,8,"A cup of mint tea for requests or gifts.",false],
		["soup","Garden soup",1,28,5,"Cooked garden soup. It can be stored or shipped.",false],
		["herb","Creek mint",2,13,6,"Two mint bundles for tea, gifts, and deliveries.",false],
	]},
}

static func is_open(model)->bool:
	return model.s.time>=HOURS.x and model.s.time<HOURS.y

static func catalog_for(model,store_name:String)->Array:
	if not STORES.has(store_name):return []
	var catalog:Array=STORES[store_name].catalog.duplicate()
	if store_name!="Farm Supply":return catalog
	var seasonal:Array=[]
	for i in range(model.crops.size()):
		if i not in [0,1] and model.season() in model.crops[i].seasons:seasonal.append(i)
	if seasonal.is_empty():return catalog
	var i:int=seasonal[(floori(float(model.s.day)/21)+1)%seasonal.size()]
	var crop:Dictionary=model.crops[i]
	catalog.append(["s"+str(i),crop.name+" seasonal packet",4,int(crop.cost)*3,3,
		"Four seeds, stocked for "+model.SEASONS[model.season()]+".",false])
	return catalog

static func stock(model,offer:Array)->int:
	if offer[6] and model.s.tools.get(offer[0],false):return 0
	var sold:int=model.s.arcade_sales.get(offer[0],0) if int(model.s.arcade_day)==int(model.s.day) else 0
	return maxi(0,int(offer[4])-sold)

static func purchase(model,store_name:String,index:int,amount:int)->String:
	if not is_open(model):return "The arcade is closed."
	if not STORES.has(store_name):return "This counter is unavailable."
	var catalog:=catalog_for(model,store_name)
	if index<0 or index>=catalog.size():return "This item is unavailable."
	var offer:Array=catalog[index]
	if amount<1 or amount>stock(model,offer):return "That quantity is no longer in stock."
	var total:int=amount*int(offer[3])
	if total>int(model.s.coins):return "You need more crowns."
	var item:String=offer[0]
	if offer[6]:
		model.install_equipment(item)
	elif not model.change(item,amount*int(offer[2])):
		return "Make room in your satchel first."
	if int(model.s.arcade_day)!=int(model.s.day):
		model.s.arcade_day=model.s.day
		model.s.arcade_sales={}
	model.s.arcade_sales[item]=int(model.s.arcade_sales.get(item,0))+amount
	model.s.coins-=total
	return ""

