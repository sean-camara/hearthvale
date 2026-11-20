extends SceneTree
const Model=preload("res://scripts/farm_state.gd")
var bad:=0
var checks:=0
func expect(ok:bool,msg:String):
	checks+=1
	if not ok:bad+=1;printerr("FAIL: "+msg)

func _initialize():call_deferred("run")
func run():
	var m=Model.new()
	m.slot=990000+randi()%9000
	expect(m.change("herb",999),"stack accepts capacity")
	expect(not m.change("herb",1) and m.qty("herb")==999,"capacity cannot overflow")
	expect(not m.change("herb",-1000),"no negative quantity")
	expect(m.transfer("herb",true) and m.transfer("herb",false),"storage round trip")
	for i in range(m.crops.size()):
		m.reset();m.s.day=int(m.crops[i].seasons[0])*21;m.s.seed=i
		var money:int=m.s.coins
		expect(m.buy(i) and m.s.coins==money-int(m.crops[i].cost),"seed purchase "+str(i))
		m.work("0,0",0);m.work("0,0",1)
		var days:int=m.crops[i].days
		for j in range(days):
			m.work("0,0",2);m.overnight()
		m.work("0,0",3)
		var product:="p"+str(i)
		expect(m.qty(product)==int(m.crops[i].yield_count),"harvest "+str(i))
		expect(m.ship(product),"ship "+str(i))
		money=m.s.coins;m.overnight()
		expect(m.s.coins==money+int(m.crops[i].price) and m.s.shipping==0,"shipment payout")
	m.reset();m.s.seed=6;m.change("s6",1);m.work("0,0",0);m.work("0,0",1)
	expect(m.s.soil["0,0"].crop==-1 and m.qty("s6")==1,"season rejection preserves seed")
	m.s.seed=0;m.work("0,0",1);m.overnight()
	expect(m.s.soil["0,0"].age==0,"dry soil cannot advance")
	m.s.day=167;m.overnight();expect(m.season()==0,"year wrap")
	expect(not m.cook("x") and not m.cook("tea"),"reject unknown and missing ingredients")
	m.change("herb",2);expect(m.cook("tea") and m.qty("tea")==1 and m.qty("herb")==0,"tea ingredients")
	m.change("p0",1);m.change("herb",1);expect(m.cook("soup"),"garden soup")
	m.s.hen=true;m.s.fed=m.s.day;m.overnight();expect(m.s.egg_day==m.s.day,"fed hen produces egg")
	m.talk("Iona");m.change("p0",1);m.talk("Iona");var reward:int=m.s.coins;m.talk("Iona")
	expect(m.s.quest==2 and m.s.coins==reward and m.s.bonds.Iona==1,"quest grants reward once")
	m.s.coins=0;expect(not m.buy(0),"insufficient funds")
	m.s.x=402;m.s.area="Village";expect(m.save_game(),"initial save")
	m.s.coins=91;expect(m.save_game(),"second save")
	for recipe in m.village.recipes:
		var kitchen=Model.new()
		for ingredient in m.village.recipes[recipe]:kitchen.change(ingredient,int(m.village.recipes[recipe][ingredient]))
		expect(kitchen.cook(recipe) and kitchen.qty(recipe)==1 and kitchen.value(recipe)>0,"cook and value "+str(recipe))
	for id in m.workshop:
		var shop=Model.new()
		expect(not shop.craft(id),"craft rejects missing wood")
		var recipe:Dictionary=shop.workshop[id]
		shop.change(recipe.get("material","wood"),int(recipe.get("count",recipe.get("wood",0))))
		expect(shop.craft(id) and shop.qty(id)==1 and shop.qty("wood")==0,"craft "+str(id))
	var n=Model.new();n.slot=m.slot;expect(n.load_game() and n.s.coins==91 and n.s.area=="Village" and n.s.soil.size()==1 and n.qty("tea")==1,"save reload")
	var f:=FileAccess.open(m.path_for(),FileAccess.WRITE);f.store_string("{");f.close()
	expect(n.load_game() and n.s.coins==0,"backup recovery")
	expect(n.save_game(),"save after recovery")
	var backup=JSON.parse_string(FileAccess.get_file_as_string(n.path_for()+".bak"))
	expect(backup is Dictionary and backup.get("version")==1,"recovery preserves known-good backup")
	for suffix in ["",".bak"]:DirAccess.remove_absolute(m.path_for()+suffix)
	print("%d model checks, %d failures"%[checks,bad]);quit(1 if bad else 0)

