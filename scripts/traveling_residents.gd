extends RefCounted

const PEOPLE:={
	"Maelin":{
		"id":"Maelin","role":"Mistfen alchemist",
		"greetings":["Moonreed folds in the rain. Cut a few stalks at the boardwalk.","The still is warm. Come in and I’ll show you how to brew."],
		"story":"I used to read the stars from the tower. Here I can see them twice, once in the sky and once in the water.",
		"gift":"moonreed",
		"request":{"title":"A scent for clear weather","item":"herb","qty":2,"reward":26,"place":"Willowbrook creek","ask":"Bring me two bundles of creek mint for the still."},
		"route":[[360,"Marsh",572,528,"Inspecting the reeds"],[560,"Marsh",702,465,"Checking the water"],[770,"AlchemyRoom",584,361,"Tending the still"],[1200,"",0,0,"Resting"]]
	},
	"Fenn":{
		"id":"Fenn","role":"Elderwood forager",
		"greetings":["There’s a cache beside the lodge. I leave cuttings for anyone coming through.","Follow the roots under the big arch. They took their time making that path."],
		"story":"My first trail guide was a woodpecker. I tried to walk as quietly as it made noise.",
		"gift":"woodland-cap",
		"request":{"title":"A print by lanternlight","item":"woodland-cap","qty":2,"reward":35,"place":"Elderwood cache and mushroom hollow","ask":"Bring two caps and I’ll make a spore print for the lodge."},
		"route":[[360,"Forest",731,530,"Sorting the cache"],[510,"Forest",590,552,"Looking for broad caps"],[720,"Forest",759,519,"Tending the lodge"],[1180,"",0,0,"Resting"]]
	},
	"Heath":{
		"id":"Heath","role":"South pasture shepherd",
		"greetings":["Cut hay from the meadow by the fence. One bundle feeds each animal for a night.","A fed sheep leaves fleece in the morning. The goat gives milk."],
		"story":"My first goat followed me into the shop. She was only interested in the paper price tags.",
		"gift":"fodder",
		"request":{"title":"Hay for the winter loft","item":"fodder","qty":3,"reward":28,"place":"South pasture meadow","ask":"Bring three hay bundles for the loft."},
		"route":[[360,"Pasture",566,457,"Checking the paddocks"],[550,"Pasture",722,479,"Tending the goats"],[780,"Pasture",397,462,"Checking the flock"],[1180,"",0,0,"Resting"]]
	},
	"Soren":{
		"id":"Soren","role":"Sunshore lighthouse keeper",
		"greetings":["I light the lamp before the gulls settle. A boat can look like a rock from up here.","The float settles first. When it dips, wait for it to cross the green band."],
		"story":"The first boat I ever guided in was smaller than my kitchen table. Its captain paid me with a bag of lemons.",
		"gift":"tide-shell",
		"request":{"title":"A shell for the light","item":"tide-shell","qty":1,"reward":26,"place":"Sunshore tidal pool at low tide","ask":"Bring me a shell from the pool. I set one on the windowsill for every ferry I see off."},
		"route":[[360,"Coast",816,478,"Polishing the lighthouse lamp"],[580,"Coast",679,423,"Checking the tide"],[820,"Coast",648,410,"Watching the float"],[1060,"Coast",927,465,"Making the evening rounds"],[1230,"",0,0,"Resting"]],
	},
	"Briar":{
		"id":"Briar","role":"Elderwood ranger",
		"greetings":["See the scrape on the old arch? A deer rubbed its antlers there while I was eating lunch.","The red caps grow by the stump. Leave the smallest ones until tomorrow."],
		"story":"I thought I knew every tree until last Raincall. I followed the creek and found one with roots like a staircase.",
		"gift":"woodland-cap",
		"request":{"title":"Briar’s field print","item":"woodland-cap","qty":1,"reward":22,"place":"Elderwood mushroom hollow","ask":"Could you bring a mushroom from the stump? I’m making a spore print for the archive."},
		"route":[[360,"Forest",551,459,"Reading tracks"],[550,"Forest",419,492,"Gathering mushrooms"],[800,"Forest",747,526,"Recording a sighting"],[1060,"Forest",548,572,"Checking the trail"],[1190,"",0,0,"Resting"]],
	},
	"Kasim":{
		"id":"Kasim","role":"Emberglass courier",
		"greetings":["If you write a letter to the mountains, fold the bottom corner. It helps me sort the sack.","The oasis flowers open after five. I try to finish the last delivery in time to see them."],
		"story":"The first letter I carried was to my own house. My sister wanted to be sure the courier would come all the way out.",
		"gift":"glassbloom",
		"request":{"title":"Pressed at sundown","item":"glassbloom","qty":1,"reward":35,"place":"Restored Emberglass oasis after 17:00","ask":"A friend up north has never seen a glassbloom. Bring one and I’ll press it into her next letter."},
		"route":[[360,"Plains",749,489,"Sorting parcels"],[580,"Plains",1039,615,"Walking the post road"],[600,"Desert",144,607,"Crossing the desert trail"],[820,"Desert",626,493,"Delivering letters"],[1060,"Desert",511,523,"Checking the dusk blooms"],[1240,"",0,0,"Resting"]],
	},
	"Astra":{
		"id":"Astra","role":"Frostpine lodge keeper",
		"greetings":["Brush the snow off your boots by the logs. It melts surprisingly fast beside the spring.","If you go into the ice cave, listen for running water. That's where I look for frost rays."],
		"story":"They said the lodge would never stay warm in Starfrost. The spring kept it warm the first winter, and every winter since.",
		"gift":"winter-sage",
		"request":{"title":"Sage for the lodge","item":"winter-sage","qty":1,"reward":28,"place":"Frostpine warm spring","ask":"Would you cut a little sage from beside the spring? A pot of tea does wonders for cold hands."},
		"route":[[360,"Frost",642,478,"Checking the spring"],[570,"Frost",710,547,"Gathering herbs"],[830,"Frost",483,543,"Checking the ice cave"],[1080,"Frost",623,470,"Making tea"],[1250,"",0,0,"Resting"]],
	},
}

static func rows(model,id:String)->Array:
	# Rotating visits put more people on Willowbrook’s streets without emptying
	# all four regions at once.
	var day:int=int(model.s.day)%7
	if day=={"Briar":1,"Kasim":3,"Soren":5,"Astra":4}.get(id,-1):
		var offset:=PEOPLE.keys().find(id)*22
		return [
			[0,"",0,0,"Resting"],[500,"Village",873,671,"Coming into Willowbrook"],
			[590,"Village",691+offset,428,"Browsing the square"],
			[760,"Village",811,527,"Reading the archive"],
			[950,"Village",910,495,"Visiting the shops"],
			[1120,"",0,0,"Returning home"],
		]
	return PEOPLE[id].route

static func uses_zone(model,id:String,zone:String)->bool:
	for row:Array in rows(model,id):
		if row[1]==zone:return true
	return false

