extends RefCounted

const Travelers=preload("res://scripts/traveling_residents.gd")
const RESOURCE_NAMES:={
	"wood":"Wood", "stone":"Fieldstone", "copper":"Copper ore", "cone":"Alder seed",
}
const NODES:={
	"alder-west":["Grove",Vector2(186,480),"oak",3,7,"wood",4,"cone"],
	"alder-south":["Grove",Vector2(517,579),"oak",3,7,"wood",4,"cone"],
	"pine-ridge":["Grove",Vector2(924,311),"pine",4,10,"wood",6,"cone"],
	"nursery":["Grove",Vector2(659,610),"oak",3,7,"wood",5,"cone"],
	"stone-bank":["Grove",Vector2(297,531),"rock",2,4,"stone",3,""],
	"stone-ridge":["Grove",Vector2(883,476),"rock",3,5,"stone",4,""],
	"copper-ledge":["Grove",Vector2(991,515),"rock",4,8,"copper",2,"stone"],
}
const BIRTHDAYS:={"Iona":15,"Oren":37,"Mara":57,"Tavi":73,"Nell":91,"Ves":115,"Linn":131,"Pip":153,"Soren":51,"Briar":28,"Kasim":108,"Astra":147}
const TOOLS:={"axe":["Axe",18],"pickaxe":["Pickaxe",20],"rod":["Willow rod",15],"rod-upgrade":["River reel",90]}
const FISH:=[
	{"id":"frost-ray","name":"Frost ray","price":38,"speed":1.82,"sites":["ice-cave"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"lake-whitefish","name":"Silverwater whitefish","price":18,"speed":1.42,"sites":["lake"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"coast-bass","name":"Sunshore bass","price":27,"speed":1.74,"sites":["sea"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"reedling","name":"Marsh reedling","price":23,"speed":1.56,"sites":["marsh"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"ice-darter","name":"Ice darter","price":28,"speed":1.67,"sites":["ice"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"glassfin","name":"Glassfin","price":36,"speed":1.87,"sites":["below"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"cave-char","name":"Lantern char","price":46,"speed":2.04,"sites":["mine"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"minnow","name":"Silver minnow","price":5,"speed":1.12,"sites":["river","pond"],"hours":[360,1440],"season":[],"wet":false},
	{"id":"perch","name":"Copper perch","price":12,"speed":1.55,"sites":["river","pond"],"hours":[360,1240],"season":[],"wet":false},
	{"id":"loach","name":"Ribbon loach","price":18,"speed":1.85,"sites":["river"],"hours":[720,1440],"season":[],"wet":false},
	{"id":"carp","name":"Amber carp","price":22,"speed":1.31,"sites":["pond"],"hours":[360,1170],"season":[],"wet":false},
	{"id":"dace","name":"Ash dace","price":16,"speed":1.62,"sites":["river"],"hours":[360,900],"season":[0,1,3,4,5],"wet":false},
	{"id":"pike","name":"Reed pike","price":35,"speed":2.02,"sites":["pond"],"hours":[600,1440],"season":[],"wet":false},
	{"id":"trout","name":"Willow trout","price":32,"speed":1.91,"sites":["river"],"hours":[360,1220],"season":[],"wet":true},
	{"id":"moonbream","name":"Moon bream","price":42,"speed":2.26,"sites":["pond"],"hours":[1080,1440],"season":[],"wet":false},
	{"id":"smelt","name":"Frost smelt","price":27,"speed":1.71,"sites":["river"],"hours":[360,1440],"season":[6,7],"wet":false},
	{"id":"sunfish","name":"Honey sunfish","price":24,"speed":1.47,"sites":["pond"],"hours":[540,1160],"season":[1,2,3,4],"wet":false},
]
const REQUESTS:={
	"Oren":{"title":"Proof of the pool","item":"carp","qty":1,"reward":42,"place":"Alderwood Pond","ask":"I keep a record of the grove's fish. Could you bring me one amber carp from the pond?"},
	"Mara":{"title":"A stave for the press","item":"wood","qty":5,"reward":30,"place":"Alderwood Grove","ask":"The spare cider press needs an alder stave. Bring me five lengths of wood and I can finish it."},
	"Ves":{"title":"Clay kiln footing","item":"stone","qty":3,"reward":28,"place":"Alderwood Grove","ask":"The kiln leans toward the path. Three pieces of fieldstone would give it a sound footing."},
	"Tavi":{"title":"Copper in the lanterns","item":"copper","qty":2,"reward":60,"place":"Alderwood Ridge","ask":"I can solder the broken lamp hinges if you bring me two pieces of copper ore from the ridge."},
	"Nell":{"title":"Tea when the rain comes","item":"tea","qty":2,"reward":31,"place":"Hearth kitchen or Copper Kettle","ask":"Could you bring two cups of mint tea? I've promised to share the first pot with Iona."},
	"Linn":{"title":"An herbarium page","item":"herb","qty":3,"reward":27,"place":"Willowbrook creek bank","ask":"I'm pressing mint leaves for the herbarium. Three creek mint bundles would fill a page."},
	"Pip":{"title":"A basket for the picnic","item":"p1","qty":2,"reward":27,"place":"Hearthvale Farmlands","ask":"Our picnic needs something crisp. Could you grow two butter lettuces?"},
}
const LIKES:={"Iona":"p0","Oren":"perch","Mara":"wood","Tavi":"copper","Nell":"tea","Ves":"stone","Linn":"herb","Pip":"p1"}
const DISLIKES:={"Iona":"copper","Oren":"p0","Mara":"loach","Tavi":"herb","Nell":"stone","Ves":"perch","Linn":"copper","Pip":"cone"}
const INTERESTS:={
	"Iona":"My aunt taught me to label a packet with the first day a seed smells sweet. That's a better calendar than most.",
	"Oren":"I carve a notch for every spring the bridge survives. It's almost time to find a longer post.",
	"Mara":"Every barrel has a high note when you tap it. I try to match the staves by ear.",
	"Tavi":"When I was small I thought the lantern flames slept in their glass by day. Some days I still check.",
	"Nell":"I'm sorting the last of my mother's seeds. She never wrote the names down, so the garden has to tell me.",
	"Ves":"On a quiet day you can hear the clay crackle just before it's ready. That's my favorite sound.",
	"Linn":"I keep a record of the first flowers after snow. The dates are starting to read like a diary.",
	"Pip":"My best picnic spot is the south bank at Alderwood, just far enough from the frogs to hear the leaves.",
}

static func available(model,site:String)->Array:
	var weather:String=model.weather(model.s.day)
	var choices=[]
	for fish:Dictionary in FISH:
		if site not in fish.sites or (fish.wet and weather!="Showers"):continue
		if model.s.time<fish.hours[0] or model.s.time>=fish.hours[1]:continue
		if not fish.season.is_empty() and model.season() not in fish.season:continue
		choices.append(fish)
	return choices

static func state(model,id:String)->Dictionary:
	return model.s.resources.get(id,{})

static func remaining(model,id:String)->int:
	return maxi(0,int(state(model,id).get("ready",0))-int(model.s.day))

static func hit(model,id:String)->Dictionary:
	if not NODES.has(id):return {}
	if id=="nursery" and not model.s.resources.has(id):return {}
	var spec:Array=NODES[id]
	var tool:="axe" if spec[5]=="wood" else "pickaxe"
	if not model.s.tools.get(tool,false):return {"message":"Buy an "+TOOLS[tool][0].to_lower()+" at the mercantile." if tool=="axe" else "Buy a pickaxe at the mercantile."}
	if remaining(model,id)>0:return {"message":"This will renew in %d days."%remaining(model,id)}
	var current:=state(model,id)
	var hits:=int(current.get("hits",0))+(2 if tool=="pickaxe" and model.s.tools.get("tempered-pick",false) else 1)
	if hits<int(spec[3]):
		model.s.resources[id]={"hits":hits}
		return {"effect":true,"message":"%d more %s."%[int(spec[3])-hits,"swings" if tool=="axe" else "strikes"]}
	if spec[7]!="" and model.qty(spec[7])>=model.CAPACITY:
		return {"message":"Make room for "+model.item_name(spec[7])+" first."}
	if not model.change(spec[5],int(spec[6])):return {"message":"Make room in your satchel first."}
	if spec[7]!="":model.change(spec[7],1)
	model.s.resources[id]={"hits":0,"ready":int(model.s.day)+int(spec[4])}
	return {"effect":true,"depleted":true,"message":"Gathered %d × %s."%[spec[6],RESOURCE_NAMES[spec[5]]]}

static func request_for(person:String)->Dictionary:
	return REQUESTS.get(person,Travelers.PEOPLE.get(person,{}).get("request",{}))

static func mission(model,person:String)->String:
	var request:=request_for(person)
	if request.is_empty():return ""
	match str(model.s.requests.get(person,"")):
		"done":return "Thanks again for helping with "+str(request.title).to_lower()+"."
		"active":
			if model.qty(request.item)<request.qty:return "Bring %d × %s. Look near %s."%[request.qty,model.item_name(request.item),request.place]
			if model.change(request.item,-int(request.qty)):
				model.s.requests[person]="done"
				model.s.coins+=int(request.reward)
				model.s.bonds[person]=int(model.s.bonds.get(person,0))+3
				return "You came through. Take these %d crowns."%request.reward
		_:
			model.s.requests[person]="active"
			return request.ask
	return ""

static func preference(person:String)->String:
	return LIKES.get(person,Travelers.PEOPLE.get(person,{}).get("gift",""))

static func gift(model,person:String,item:String)->String:
	if item not in [preference(person),DISLIKES.get(person,"")] and not (person=="Linn" and item=="p0"):return ""
	if int(model.s.gifts.get(person,-1))==int(model.s.day):return "Let's save something for another day."
	if not model.change(item,-1):return "You don't have that in your satchel."
	model.s.gifts[person]=model.s.day
	var liked:bool=preference(person)==item or (person=="Linn" and item=="p0")
	var gain:=5 if birthday(model,person) else 3
	model.s.bonds[person]=maxi(0,int(model.s.bonds.get(person,0))+(gain if liked else -1))
	model.s.moods[person]=["Happy" if liked else "Uneasy",model.s.day]
	return "You remembered what I like. Thank you." if liked else "Thank you for thinking of me. I don't use much of this."

static func mood(model,person:String)->String:
	var recorded:Array=model.s.moods.get(person,[])
	if recorded.size()==2 and int(recorded[1])==int(model.s.day):return recorded[0]
	if model.is_fair() or birthday(model,person):return "Excited"
	if model.s.time<460 or model.s.time>1180:return "Tired"
	if model.weather(model.s.day)=="Showers":return "Relaxed" if person in ["Oren","Linn"] else "Worried"
	if int(model.s.bonds.get(person,0))>=4:return "Happy"
	return "Relaxed"


static func birthday(model,person:String)->bool:
	return int(model.s.day)%168==int(BIRTHDAYS.get(person,-1))

static func seed(model)->bool:
	if model.s.resources.has("nursery") or not model.change("cone",-1):return false
	model.s.resources.nursery={"ready":int(model.s.day)+6,"hits":0}
	return true
