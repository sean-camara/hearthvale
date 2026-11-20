extends RefCounted

const Travelers=preload("res://scripts/traveling_residents.gd")
const Art="res://assets/valley/"
const Life=preload("res://scripts/world_life.gd")

func build(game,person:Dictionary,line:String,mood:String):
	var canvas:Control=game.overlay
	var shade:=ColorRect.new()
	shade.size=Vector2(1280,720)
	shade.color=Color("#171b175b")
	canvas.add_child(shade)

	var compact:bool=line.length()<105 and not game.model.s.expansion.projects.get("large-print",false)
	var cut:=32 if compact else 0
	var frame:Panel=game.farm_hud.plaque(game,canvas,Vector2(104,449+cut),Vector2(1072,246-cut))
	var card:Panel=game.panel(frame,Vector2(14,15),Vector2(1044,215-cut))
	card.add_theme_stylebox_override("panel",game.style(Color("#2c2019"),Color("#ac8054"),0))
	var portrait_frame:Panel=game.panel(card,Vector2(13,11),Vector2(150,191-cut))
	portrait_frame.add_theme_stylebox_override("panel",game.style(Color("#51423a"),Color("#ba9268"),0))
	var portrait_id:String=person.id.to_lower()
	var expression:=""
	if mood in ["Happy","Excited"]:expression="-happy"
	if mood in ["Worried","Uneasy","Tired"]:expression="-worried"
	var path:=Art+"portrait-"+portrait_id+expression+".png"
	if Travelers.PEOPLE.has(person.id):
		path="res://assets/life/portrait-"+portrait_id+".png"
		if not ResourceLoader.exists(path):path="res://assets/trails/"+portrait_id+".png"
	elif not ResourceLoader.exists(path):path=Art+"portrait-"+portrait_id+".png"
	var portrait:TextureRect=game.farm_hud.stamp(portrait_frame,load(path),Vector2(7,7),Vector2(136,178-cut))
	portrait.size=Vector2(136,178-cut)
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	game.place(card,game.lbl(person.id,34,Color("#f3d6a0"),true),181,10)
	var bond:int=game.model.s.bonds.get(person.id,0)
	var level:="Close friend" if bond>=14 else ("Friend" if bond>=6 else "Getting acquainted")
	var details:Label=game.lbl("%s  ·  %s  ·  %s"%[person.role,mood,level],15,Color("#dec099"))
	game.place(card,details,183,54)
	var text:Label=game.lbl(line,20,Color("#f9ecd2"))
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.size=Vector2(812,65)
	game.place(card,text,183,83)
	var tween:Tween=text.create_tween()
	text.visible_ratio=0
	tween.tween_property(text,"visible_ratio",1.0,minf(.54, float(line.length())*.009))
	game.dialogue_text=text
	game.dialogue_tween=tween

	var x:=183
	var options:=[
		["Talk  ›" if bond<6 or game.model.s.friend_events.has(person.id) else "Share a story",game.dialogue_topic.bind("talk"),135],
		["Request",game.dialogue_topic.bind("request"),129],
		["Give a gift",game.show_page.bind("Gifts"),150],
		["Goodbye",game.close_page,124],
	]
	if person.id in ["Oren","Mara"]:
		options.insert(2,["Dock project",game.dialogue_topic.bind("dock"),142])
	if person.id=="Oren" and game.world.area in ["Farm","Village"] and absf(game.world.pos.x-game.world.cast_point("river").x)<165:
		options=[["Talk",game.dialogue_topic.bind("talk"),88],["Request",game.dialogue_topic.bind("request"),100],["Dock project",game.dialogue_topic.bind("dock"),122],["Practice cast",game.practice_with_oren,132],["Give a gift",game.show_page.bind("Gifts"),110],["Goodbye",game.close_page,106]]
	if person.id=="Linn" and game.model.s.requests.get("Linn","")=="done":
		options.insert(2,["Dawn walk",game.show_page.bind("Linn’s dawn walk"),132])
	if person.id=="Maelin":
		options.insert(2,["Apothecary",game.interact.bind(game.HomesteadLife.Alchemy),140] if game.world.area=="Marsh" else ["Alchemy",game.show_page.bind("Alchemy bench"),135])
	if person.id=="Fenn":
		options.insert(2,["Trade",game.show_page.bind(game.HomesteadLife.ForestLodge),128])
	if person.id=="Heath":
		options.insert(2,["Livestock",game.show_page.bind(game.HomesteadLife.Stock),131])
	if person.id=="Iona":
		options.insert(2,["Market supper",game.show_page.bind("Willowbrook market supper"),156])
	for spec in options:
		var button:Button=game.btn(spec[0],spec[1])
		game.farm_hud.list_button(game,button)
		if options.size()==6:
			for state:String in ["normal","hover","pressed"]:
				var paper:StyleBoxFlat=button.get_theme_stylebox(state).duplicate()
				paper.content_margin_left=5
				paper.content_margin_right=5
				button.add_theme_stylebox_override(state,paper)
		button.size=Vector2(spec[2],40)
		button.custom_minimum_size=Vector2(spec[2],40)
		game.place(card,button,x,164-cut)
		x+=spec[2]+12
	game.place(card,game.keycap("Esc"),972,165-cut)


