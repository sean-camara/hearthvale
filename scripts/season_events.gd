extends RefCounted

const TITLES:=["Seedwake Seed Fair","Bloomrise Tea Table","Suncrest Basket Day","Raincall Pantry Swap",
	"Goldleaf Harvest Table","Emberfall Lantern Market","Snowrest Trading Day","Starfrost Farewell"]
const DESCRIPTIONS:=["","Bring something green to welcome the year’s first blossoms.",
	"Bring a crop for the summer baskets beside the well.",
	"Help the village stock its pantry against a week of showers.",
	"Add a ripe crop to the harvest table in the square.",
	"Bring one last crop before the village hangs its lanterns.",
	"Help fill the communal pantry before the cold takes hold.",
	"Put one crop on the farewell table before Seedwake returns."]

static func available(model)->bool:
	return model.season()>0 and int(model.s.day)%21==14

static func produce(model)->int:
	var eligible:Array[int]=[]
	for i in range(model.crops.size()):
		if model.season() in model.crops[i].seasons:eligible.append(i)
	return eligible[(model.season()+floori(float(model.s.day)/168))%eligible.size()] if not eligible.is_empty() else 0

static func reward(model)->String:
	if not available(model):return "The stall opens on the fifteenth day of this season."
	var year_key:=str(floori(float(model.s.day)/21))
	if model.s.season_events.has(year_key):return "You’ve already contributed this season."
	var i:=produce(model)
	var seed:="s"+str(i)
	if model.qty(seed)+3>model.CAPACITY:return "Make room for three seeds before contributing."
	if not model.change("p"+str(i),-1):return "Bring one "+model.crops[i].name+"."
	model.change(seed,3)
	model.s.coins+=24
	model.s.season_events[year_key]=true
	return ""

