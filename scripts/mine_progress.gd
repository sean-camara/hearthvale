extends RefCounted

const DEPTHS:=9
const ENTRY:=Vector2(576,488)
const EXIT:=Vector2(960,487)
const DOCK:=Vector2(247,411)
const ORES:=["stone","copper","coal","iron-ore","moonstone"]
const TITLES:=["The Old Quarry","Glowcap Caverns","The Flooded Galleries"]
const FOOD:={"soup":48,"tea":20,"p0":12,"p1":14}
const RECIPES:={
	"copper-bar":{"copper":3,"coal":1},
	"iron-bar":{"iron-ore":3,"coal":1},
	"tempered-pick":{"copper-bar":2,"iron-bar":1},
	"sprinkler":{"copper-bar":2,"iron-bar":2},
}
const NAMES:={
	"coal":"Coal","iron-ore":"Iron ore","moonstone":"Moonstone",
	"copper-bar":"Copper bar","iron-bar":"Iron bar",
	"tempered-pick":"Tempered pickaxe","mine-lantern":"Mine lantern",
}
const PRICES:={"coal":4,"iron-ore":18,"moonstone":48,"copper-bar":47,"iron-bar":68}
const PUZZLE_SEEDS:=[
	[Vector2(398,367),Vector2(735,347),Vector2(461,289),Vector2(648,279),Vector2(791,424),Vector2(340,419)],
	[Vector2(360,393),Vector2(779,389),Vector2(480,331),Vector2(679,329),Vector2(674,447),Vector2(386,291)],
	[Vector2(402,424),Vector2(737,425),Vector2(502,288),Vector2(669,284),Vector2(780,340),Vector2(358,325)],
]

static func defaults()->Dictionary:
	return {"depth":1,"lift":1,"best":1,"energy":100.0,"fuel_until":-1.0,"day":-1,
		"nodes":{},"cleared":{},"beaten":{},"rain_catch":false,"dock_stage":0,"started":-1,"supper":-1}

static func clock(model)->float:
	return int(model.s.day)*1440.0+float(model.s.time)

static func lit(model)->bool:
	return clock(model)<float(model.s.mine.fuel_until)

static func refresh(model):
	if int(model.s.mine.day)==int(model.s.day):return
	model.s.mine.day=model.s.day
	model.s.mine.nodes={}
	model.s.mine.cleared={}
	model.s.mine.beaten={}

static func band(depth:int)->int:return clampi(floori((depth-1)/3.0),0,2)

static func title(depth:int)->String:return TITLES[band(depth)]

static func nodes(depth:int)->Array:
	var points:Array=PUZZLE_SEEDS[(depth-1)%3]
	var pool:=[["copper","stone","coal","copper","coal","stone"],
		["iron-ore","copper","coal","iron-ore","stone","moonstone"],
		["iron-ore","moonstone","coal","iron-ore","moonstone","copper"]]
	var entries:Array=[]
	for i in range(points.size()):
		var ore:String=pool[band(depth)][(i+floori((depth-1)/2.0))%6]
		entries.append({"id":"%d:%d"%[depth,i],"at":points[i],"ore":ore})
	return entries

static func exhausted(model)->bool:return float(model.s.mine.energy)<=0

static func strike(model,depth:int,index:int)->Dictionary:
	refresh(model)
	if not model.s.tools.get("pickaxe",false) and not model.s.tools.get("tempered-pick",false):return {"message":"Bring a pickaxe from Willowbrook."}
	var entries:=nodes(depth)
	if index<0 or index>=entries.size():return {}
	var node:Dictionary=entries[index]
	var hits:int=model.s.mine.nodes.get(node.id,0)
	if hits<0:return {}
	var work:=1+(1 if model.s.tools.get("tempered-pick",false) else 0)
	var limit:=3 if node.ore in ["iron-ore","moonstone"] else 2
	var done:=hits+work>=limit
	var qty:=1 if node.ore=="moonstone" else 2
	if done and not model.change(node.ore,qty):return {"message":"Your satchel is full."}
	model.s.mine.energy=maxf(0,float(model.s.mine.energy)-3.5)
	model.s.mine.nodes[node.id]=-1 if done else hits+work
	if done:
		var key:=str(depth)
		model.s.mine.cleared[key]=int(model.s.mine.cleared.get(key,0))+1
	return {"effect":true,"done":done,"at":node.at,"message":("Mined %d × %s"%[qty,model.item_name(node.ore)]) if done else "The vein cracks under the pickaxe."}

static func descend(model)->bool:
	refresh(model)
	var depth:=int(model.s.mine.depth)
	if depth>=DEPTHS or int(model.s.mine.cleared.get(str(depth),0))<2:return false
	model.s.mine.depth=depth+1
	model.s.mine.best=maxi(int(model.s.mine.best),depth+1)
	return true

static func open_lift(model)->bool:
	var depth:=int(model.s.mine.depth)
	if depth not in [3,6,9] or depth<=int(model.s.mine.lift):return false
	model.s.mine.lift=depth
	return true

static func craft(model,id:String)->String:
	if not RECIPES.has(id):return ""
	var gear:=id in ["tempered-pick","sprinkler"]
	if gear and model.s.tools.get(id,false):return "Already installed."
	var needs:Dictionary=RECIPES[id]
	for item:String in needs:
		if model.qty(item)<int(needs[item]):return "Bring all the listed materials."
	if not gear and not model.change(id,1):return "Make space in your satchel."
	for item:String in needs:model.change(item,-int(needs[item]))
	if gear:model.install_equipment(id)
	return ""

static func dock_status(model)->String:
	match int(model.s.mine.dock_stage):
		0:return "Ask Oren about the creek and the old dock."
		1:return "Catch a creek fish during showers, then tell Oren."
		2:return "Reopen the lift on mine level 3. Then speak to Mara."
		3:return "Bring Mara 6 wood and 2 copper bars for the dock."
		4:return "Meet the village at the restored dock, day %d at 18:00."%(int(model.s.mine.supper)+1)
	return "The restored dock is open. Look for Oren fishing there in the afternoon."

static func dock_talk(model,person:String)->String:
	var stage:=int(model.s.mine.dock_stage)
	if stage==0 and person=="Oren":
		model.s.mine.dock_stage=1
		model.s.mine.started=model.s.day
		model.change("bait",2)
		return "Rain brings the creek fish out. Try a cast when it rains. Here’s some bait. Then we can talk about bringing back the old dock."
	if stage==1 and person=="Oren" and model.s.mine.rain_catch:
		model.s.mine.dock_stage=2
		return "Now you know what rain does to the creek. Mara can rebuild the dock, but first reopen the lift on level three so we can haul fittings."
	if stage==2 and person=="Mara" and int(model.s.mine.lift)>=3:
		model.s.mine.dock_stage=3
		return "With the lift running, I can haul the planks. Bring six wood and two copper bars. Ves’s furnace is at the arcade hardware counter."
	if stage==3 and person=="Mara" and model.qty("wood")>=6 and model.qty("copper-bar")>=2:
		model.change("wood",-6)
		model.change("copper-bar",-2)
		model.s.mine.dock_stage=4
		model.s.mine.supper=maxi(int(model.s.mine.started)+6,int(model.s.day)+1)
		return "The dock is ready. We’ll put a table by the water on day %d at six in the evening."%(int(model.s.mine.supper)+1)
	return dock_status(model)

static func supper(model)->bool:
	if int(model.s.mine.dock_stage)!=4 or int(model.s.day)<int(model.s.mine.supper) or model.s.time<1080 or model.s.time>=1320:return false
	model.s.mine.dock_stage=5
	model.s.coins+=70
	for person in ["Oren","Mara","Pip"]:
		model.s.bonds[person]=int(model.s.bonds.get(person,0))+2
	return true

