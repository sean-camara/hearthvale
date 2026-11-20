extends SceneTree
const Model=preload("res://scripts/farm_state.gd")
var count:=0
var failures:=0
func check(ok:bool,what:String):
	count+=1
	if not ok:
		failures+=1;printerr("FAIL: "+what)
func _initialize():call_deferred("run")

func run():
	var m=Model.new()
	m.slot=400000+randi()%50000
	# A pre-overhaul save had no homestead fields. Round-trip it without touching player slots.
	var legacy:Dictionary=m.s.duplicate(true)
	for key in ["completed_orders","upgrades","harvest_book","packet_period","batch"]:legacy.erase(key)
	legacy.coins=87;legacy.soil={"4,2":{"crop":2,"age":1,"wet":true}}
	var file:=FileAccess.open(m.path_for(),FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	check(m.load_game() and m.s.coins==87 and m.s.soil["4,2"].age==1 and m.s.upgrades.is_empty(),"old v1 farm gains optional fields")
	m.reset()
	var rewards:int=0
	for day in range(168):
		var season:int=m.season()
		if day%21==0:
			var cultivar:int=m.home.available_crops(m)[0]
			m.s.seed=cultivar
			check(m.buy(cultivar),"seed counter stocks seasonal crop")
			m.work("0,0",0);m.work("0,0",1)
		var plot:Dictionary=m.s.soil["0,0"]
		if plot.crop>=0:
			if plot.age>=m.crops[int(plot.crop)].days:
				m.work("0,0",3)
				check(m.s.harvest_book.has(str(season)),"seasonal harvest recorded")
			else:m.work("0,0",2)
		if day%7==0:
			var orders:Array=m.home.orders(m)
			check(orders.size()==3,"three market orders in each week")
			var order:Dictionary=orders[0]
			var prior:int=m.s.coins
			if m.qty(order.item)<order.qty:
				check(not m.home.deliver(m,order.key) and m.s.coins==prior,"missing produce can't collect reward")
			# Fixture supplies isolate the weekly transaction from the separate crop test.
			m.change(order.item,order.qty)
			check(m.home.deliver(m,order.key) and m.s.coins==prior+int(order.reward),"exact reward and delivery")
			check(not m.home.deliver(m,order.key),"no double redemption")
			rewards+=1
		m.overnight()
	check(m.s.day==168 and m.season()==0 and m.s.harvest_book.size()==8,"one full year, eight harvest stamps")
	check(m.s.completed_orders.size()==rewards and rewards==24,"all weekly deliveries persist")
	check(not m.home.deliver(m,"0-0"),"expired order cannot redeem")
	check(not m.home.restore(m,"library"),"cannot restore with insufficient wood")
	m.change("wood",80);m.s.coins+=600
	for id in ["library","cistern","kettle"]:
		check(m.home.restore(m,id) and not m.home.restore(m,id),"project can only be paid for once")
	check(m.home.claim_packet(m) and not m.home.claim_packet(m),"one seed packet per season")
	m.s.day+=21;check(m.home.claim_packet(m),"next season restocks cabinet")
	m.work("4,0",0);m.work("4,1",0)
	m.s.day=2;m.overnight()
	check(m.s.soil["4,0"].wet,"irrigation wets north row")
	m.change("p5",3)
	check(m.home.simmer(m,5) and not m.home.simmer(m,5) and not m.home.collect(m),"kettle accepts exactly one overnight batch")
	m.save_game()
	var n=Model.new();n.slot=m.slot
	check(n.load_game() and n.s.upgrades.size()==3 and n.s.harvest_book.size()==8 and n.s.batch.crop==5,"projects and cooking survive reload")
	n.overnight();check(n.home.collect(n) and n.qty("jar5")==1 and not n.home.collect(n),"collect jar once")
	check(n.ship("jar5") and n.s.shipping==int(n.crops[5].price)*4+8,"preserves sale")
	for suffix in ["",".bak"]:DirAccess.remove_absolute(n.path_for()+suffix)
	print("%d year and restoration checks, %d failures"%[count,failures]);quit(1 if failures else 0)

