extends RefCounted

const Travelers=preload("res://scripts/traveling_residents.gd")
const Mine=preload("res://scripts/mine_progress.gd")
const Rooms=preload("res://scripts/arcade_rooms.gd")
const Stock=preload("res://scripts/arcade_stock.gd")
const Routes=preload("res://scripts/world_routes.gd")
const ROWS:={
	"Iona":[[360,"Village",482,330,"Arranging seed packets"],[540,"Mercantile",628,326,"Tending the counter"],[780,"Village",564,344,"Checking the market"],[850,"Mercantile",628,326,"Tending the counter"],[1140,"Village",330,294,"Closing up"],[1210,"",0,0,"Resting"]],
	"Oren":[[360,"Village",354,296,"Checking river levels"],[483,"Village",15,334,"Crossing Mill Bridge"],[484,"Farm",1137,334,"Crossing Mill Bridge"],[493,"Farm",931,393,"Fishing Willow Creek"],[849,"Farm",1137,334,"Returning to Willowbrook"],[850,"Village",15,334,"Returning to Willowbrook"],[864,"Village",247,358,"Checking the bridge lanterns"],[1160,"Village",317,296,"Heading home"],[1230,"",0,0,"Resting"]],
	"Mara":[[360,"Village",297,318,"Taking the morning air"],[480,"Mercantile",628,326,"Opening the counter"],[548,"Village",460,294,"Checking the well bucket"],[710,"Village",585,426,"Taking a break"],[797,"Village",359,310,"Measuring oak staves"],[1130,"Village",292,317,"Heading home"],[1200,"",0,0,"Resting"]],
	"Tavi":[[360,"Village",727,320,"Cleaning lamp glass"],[700,"Village",618,390,"Inspecting the plaza lamps"],[860,"Village",728,291,"Bringing a lamp to the bakery"],[1040,"Village",245,353,"Lighting the west approach"],[1180,"Village",359,294,"Heading home"],[1240,"",0,0,"Resting"]],
	"Nell":[[360,"Village",605,312,"Sorting seeds"],[550,"Village",560,351,"Checking the stall"],[686,"Village",620,450,"Taking a break"],[830,"Village",515,348,"Folding seed envelopes"],[1120,"Village",322,309,"Heading home"],[1170,"",0,0,"Resting"]],
	"Ves":[[360,"Village",285,385,"Taking clay to dry"],[530,"Village",367,418,"Inspecting pottery"],[740,"Village",456,294,"Taking a break at the well"],[871,"Village",327,412,"Packing finished pots"],[1130,"Village",280,386,"Heading home"],[1210,"",0,0,"Resting"]],
	"Linn":[[360,"Village",807,376,"Checking creek mint"],[525,"Village",733,26,"Heading into the grove"],[526,"Grove",733,752,"Walking the trail"],[541,"Grove",456,505,"Studying pond lilies"],[865,"Grove",733,752,"Returning to Willowbrook"],[866,"Village",733,26,"Returning to Willowbrook"],[882,"Village",778,392,"Gathering herbs"],[1160,"Village",321,305,"Heading home"],[1220,"",0,0,"Resting"]],
	"Pip":[[360,"Village",719,284,"Opening the bakery"],[420,"Bakery",624,335,"Serving the bakery counter"],[1200,"Village",719,284,"Closing up the bakery"],[1240,"",0,0,"Resting"]],
}
var grid:=AStarGrid2D.new()
var footprints:Dictionary={}
const HOME:={"Oren":"RiverLodge","Linn":"Herbarium","Nell":"Herbarium","Mara":"CraftsHouse","Ves":"CraftsHouse","Tavi":"CraftsHouse","Iona":"SeedLoft","Pip":"BakerLoft"}
const HOME_BREAKFAST:={"RiverLodge":Vector2(605,397),"Herbarium":Vector2(647,418),"CraftsHouse":Vector2(477,418),"SeedLoft":Vector2(667,391),"BakerLoft":Vector2(610,416)}
var zone:=""
var cached_day:=-1
var cached_dock:=-1
var cached_linn:=-1
var itineraries:={}
var world

func setup(region:String,owner):
	zone=region
	world=owner
	footprints.clear()
	itineraries.clear()
	cached_day=-1
	grid.region=Rect2i(1,3,143,92)
	grid.cell_size=Vector2(8,8)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var r:=grid.region
	for y in range(r.position.y,r.end.y):
		for x in range(r.position.x,r.end.x):
			var cell:=Vector2i(x,y)
			grid.set_point_solid(cell,world.blocked(Vector2(cell)*8))

func nearest_free(at:Vector2)->Vector2i:
	var center:=Vector2i((at/8).round()).clamp(grid.region.position,grid.region.end-Vector2i.ONE)
	if not grid.is_point_solid(center):return center
	for radius in range(1,12):
		var best:=center
		var best_distance:=INF
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				if abs(x)!=radius and abs(y)!=radius:continue
				var next:=center+Vector2i(x,y)
				if not grid.region.has_point(next) or grid.is_point_solid(next):continue
				var distance:=(Vector2(next)*8).distance_squared_to(at)
				if distance<best_distance:
					best=next
					best_distance=distance
		if best!=center:return best
	return center

func schedule(model,id:String)->Array:
	if Travelers.PEOPLE.has(id):return Travelers.rows(model,id)
	var day:=int(model.s.day)
	var dock_stage:=int(model.s.mine.dock_stage)
	var linn_phase:int=int(model.s.expansion.linn_supper and not model.s.expansion.linn_cooked)+2*int(model.s.expansion.projects.get("greenhouse",false))
	if cached_day!=day or cached_dock!=dock_stage or cached_linn!=linn_phase:
		cached_linn=linn_phase
		cached_day=day
		cached_dock=dock_stage
		itineraries.clear()
	if itineraries.has(id):return itineraries[id]
	var rows:Array=ROWS[id].duplicate(true)
	if model.is_fair() and id not in ["Iona","Pip","Mara"]:
		var index:=["Oren","Tavi","Nell","Ves","Linn"].find(id)
		rows=[rows[0],[475,"Village",572+index*29,416+index%2*16,"Visiting the Seedwake fair"],rows[-2],rows.back()]
	elif day%7==5 and id=="Mara":
		rows[3]=[710,"Village",592,502,"Buying lunch at the square"]
	if model.s.expansion.projects.get("south-bridge",false) and day%7==2:
		if id=="Ves":
			rows.append([752,"Grove",714,693,"Crossing the restored footbridge"])
			rows.append([768,"Farm",721,627,"Checking the new stonework"])
			rows.append([807,"Grove",714,693,"Returning across the footbridge"])
		elif id=="Oren":
			rows.append([720,"Farm",721,636,"Fishing beside the footbridge"])
			rows.append([758,"Farm",931,393,"Fishing Willow Creek"])
	if id in ["Tavi","Ves","Nell"] and not model.is_fair():
		var queue_index:=["Tavi","Ves","Nell"].find(id)
		rows=rows.filter(func(task):return task[0]<537 or task[0]>=726)
		rows.append([540,"Village",922+queue_index*15,480+queue_index*5,"Browsing the growers’ stalls"])
		rows.append([715,"Village",922+queue_index*15,480+queue_index*5,"Choosing produce for supper"])
	if id=="Linn" and model.weather(day)=="Showers" and not model.is_fair():
		rows.append([477,"Village",568,325,"Sheltering under the striped awning"])
	if HOME.has(id):
		var home:String=HOME[id]
		var bed:Vector2=Rooms.BEDS[id]
		rows[0][0]=376+["Oren","Linn","Nell","Mara","Ves","Tavi","Iona","Pip"].find(id)*3
		var breakfast:Vector2=HOME_BREAKFAST[home]
		rows.push_front([360,home,breakfast.x,breakfast.y,"Having breakfast"])
		rows.push_front([0,home,bed.x,bed.y,"Sleeping"])
		var evening:float=rows.back()[0]
		rows[-1]=[evening,home,breakfast.x,breakfast.y,"Reading before bed"]
		rows.append([1320,home,bed.x,bed.y,"Sleeping"])
		if home in ["SeedLoft","BakerLoft"]:
			var downstairs:String=Routes.DOORS[home][0]
			rows.append([382,downstairs,797,351,"Coming downstairs"])
			rows[2][0]=405
			rows.append([evening-18,downstairs,797,351,"Going upstairs"])
	# Existing morning/evening routines stay in place around a shared afternoon shift.
	if not model.is_fair():
		for counter:String in Stock.STORES:
			var stall:Dictionary=Stock.STORES[counter]
			if stall.keeper!=id:continue
			rows=rows.filter(func(row):return row[0]<904 or row[0]>=1050)
			var at:Vector2=stall.at
			rows.append([918,"Arcade",at.x+49,at.y-3,"Serving the arcade counter"])
			rows.append([1044,"Village",982,347,"Walking back from the arcade"])
			break
	if id=="Linn":
		if model.s.expansion.linn_supper and not model.s.expansion.linn_cooked:
			rows=rows.filter(func(task):return task[0]<1077 or task[0]>=1230)
			rows.append([1080,"Herbarium",Vector2(647,418).x,Vector2(647,418).y,"Stirring the supper pot"])
		elif model.s.expansion.projects.get("greenhouse",false) and model.weather(day)=="Showers":
			rows=rows.filter(func(task):return task[0]<580 or task[0]>=870)
			rows.append([600,"Farm",794,359,"Tending the greenhouse seedlings"])
	if dock_stage>=4:
		if id=="Oren":
			for task:Array in rows:
				if task[4]=="Checking the bridge lanterns":
					task[2]=230
					task[3]=409
					task[4]="Fishing from the restored dock"
		if id in ["Oren","Mara","Pip"] and day>=int(model.s.mine.supper) and (dock_stage==4 or day==int(model.s.mine.supper)):
			rows=rows.filter(func(task):return task[0]<1077 or task[0]>=1195)
			var seat:Vector2={"Oren":Vector2(247,394),"Mara":Vector2(280,394),"Pip":Vector2(308,376)}[id]
			rows.append([1080,"Village",seat.x,seat.y,"Having supper by the dock"])
	rows.sort_custom(func(a,b):return a[0]<b[0])
	var itinerary:=[rows[0]]
	for i in range(1,rows.size()):
		var from:Array=rows[i-1]
		var to:Array=rows[i]
		var current:String=from[1]
		var next:String=to[1]
		var time:float=to[0]
		if next!=current and Routes.DOORS.has(current) and Routes.DOORS.has(next) and Routes.DOORS[current][0]==Routes.DOORS[next][0]:
			# Walk from one business to the next through their shared exterior.
			var source:Array=Routes.DOORS[current]
			var destination:Array=Routes.DOORS[next]
			var from_door:Vector2=source[2]
			var to_door:Vector2=destination[2]
			itinerary.append([time-17,current,577,498,"Heading out"])
			itinerary.append([time-15,source[0],from_door.x,from_door.y,"Stepping outside"])
			itinerary.append([time-2,source[0],to_door.x,to_door.y,"Heading inside"])
			itinerary.append([time,next,577,498,"Arriving"])
			to[0]=time+4.0
		elif next!=current and Routes.DOORS.has(next) and Routes.DOORS[next][0]==current:
			var threshold:Vector2=Routes.DOORS[next][2]
			itinerary.append([time-2,current,threshold.x,threshold.y,"Heading inside"])
			itinerary.append([time,next,577,498,"Arriving"])
			to[0]=time+4.0
		elif next!=current and Routes.DOORS.has(current) and Routes.DOORS[current][0]==next:
			var threshold:Vector2=Routes.DOORS[current][2]
			var inside_start:Vector2=Routes.DOORS[current][1]
			if next in Routes.OUTDOORS:inside_start=Vector2(577,498)
			itinerary.append([time-2,current,inside_start.x,inside_start.y,"Heading out"])
			itinerary.append([time,next,threshold.x,threshold.y,"Stepping outside"])
			to[0]=time+4.0
		itinerary.append(to)
	itineraries[id]=itinerary
	return itinerary

func sample(model,id:String)->Dictionary:
	var rows:=schedule(model,id)
	var moment:=float(model.s.time)
	var index:=0
	while index+1<rows.size() and moment>=float(rows[index+1][0]):index+=1
	var here:Array=rows[index]
	if here[1]!=zone:return {}
	var point:=Vector2(here[2],here[3])
	var result:={"position":world_point(point),"moving":false,"activity":here[4]}
	if index+1>=rows.size():return result
	var next:Array=rows[index+1]
	if next[1]!=zone:return result
	var route:=path(point,Vector2(next[2],next[3]))
	if route.size()<2:return result
	var steps:=route.size()-1
	var duration:=clampf(steps*.13,1.0,11.0)
	if model.weather(model.s.day)=="Showers":duration*=1.3
	var offset:=clampf((moment-float(next[0])+duration)/duration,0,1)*steps
	if offset<=0:return result
	var i:=mini(steps-1,floori(offset))
	var direction:Vector2=route[i+1]-route[i]
	return {"position":route[i].lerp(route[i+1],offset-i),"moving":true,"activity":next[4],"direction":direction}

func world_point(at:Vector2)->Vector2:
	return at if not world.blocked(at) else Vector2(nearest_free(at))*8

func path(start:Vector2,finish:Vector2)->PackedVector2Array:
	var key:=str(start)+"|"+str(finish)
	if not footprints.has(key):
		var aim:=nearest_free(finish)
		var route:=grid.get_point_path(nearest_free(start),aim)
		if route.size()>0 and route[-1].distance_to(Vector2(aim)*8)<.1:
			route[0]=world_point(start)
			route[-1]=world_point(finish)
		footprints[key]=route
	return footprints[key]

