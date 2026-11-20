extends RefCounted

var book:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/homestead.json"))

func available_crops(m)->Array[int]:
	var ids:Array[int]=[]
	for i in range(m.crops.size()):
		if m.season() in m.crops[i].seasons:ids.append(i)
	return ids

func orders(m)->Array:
	var week:=floori(float(m.s.day)/7)
	var ids:=available_crops(m)
	var crop_index:int=ids[week%ids.size()]
	var pantry:Array[String]=["tea","soup","fishcake","grilled"]
	var seasonal_meals:Array[String]=[]
	for recipe:String in m.village.recipes:
		if recipe in pantry:continue
		if m.village.recipes[recipe].has("p"+str(crop_index)):seasonal_meals.append(recipe)
	var dish:String=pantry[week%pantry.size()]
	if week%2==1 and not seasonal_meals.is_empty():dish=seasonal_meals[0]
	var supply:String=["wood","herb","egg","minnow","bench","perch"][week%6]
	var supply_amount:int={"wood":6,"herb":3,"egg":2,"minnow":2,"bench":1,"perch":1}[supply]
	var requests:Array=[["p"+str(crop_index),2+week%3],[dish,1],[supply,supply_amount]]
	var theme:Array=book.seasons[m.season()]
	var result:Array=[]
	for i in range(3):
		var item:String=requests[i][0]
		var count:int=requests[i][1]
		var price:int=maxi(m.value(item),4 if item=="wood" else 19)
		var reward:=ceili(price*count*1.3)+5
		result.append({"key":"%d-%d"%[week,i],"person":theme[i+1],"story":theme[i+4],"item":item,"qty":count,"reward":reward})
	return result

func deliver(m,key:String)->bool:
	for order in orders(m):
		if order.key!=key or m.s.completed_orders.has(key):continue
		if not m.change(order.item,-int(order.qty)):return false
		m.s.coins+=int(order.reward)
		m.s.completed_orders[key]=true
		return true
	return false

func project(id:String)->Dictionary:
	for project_ in book.projects:
		if project_.id==id:return project_
	return {}

func restore(m,id:String)->bool:
	var plan:=project(id)
	if plan.is_empty() or m.s.upgrades.has(id):return false
	if m.s.completed_orders.size()<int(plan.orders) or m.s.coins<int(plan.coins):return false
	if not m.change("wood",-int(plan.wood)):return false
	m.s.coins-=int(plan.coins);m.s.upgrades[id]=true
	return true

func claim_packet(m)->bool:
	var period:=floori(float(m.s.day)/21)
	if not m.s.upgrades.has("library") or int(m.s.packet_period)==period:return false
	var ids:=available_crops(m)
	var item:="s"+str(ids[period%ids.size()])
	if not m.change(item,4):return false
	m.s.packet_period=period
	return true

func simmer(m,crop:int)->bool:
	if not m.s.upgrades.has("kettle") or crop<0 or crop>=m.crops.size() or not m.s.batch.is_empty():return false
	if not m.change("p"+str(crop),-3):return false
	m.s.batch={"crop":crop,"ready":int(m.s.day)+1}
	return true

func collect(m)->bool:
	if m.s.batch.is_empty() or int(m.s.day)<int(m.s.batch.ready):return false
	if not m.change("jar"+str(int(m.s.batch.crop)),1):return false
	m.s.batch={}
	return true

func record_harvest(m,crop:int):
	if m.season() in m.crops[crop].seasons:m.s.harvest_book[str(m.season())]=true

