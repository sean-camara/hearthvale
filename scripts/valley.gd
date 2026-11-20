extends Node2D

signal used(target:String)
signal crossed(region:String,side:String,position_:Vector2)
signal step_message(message:String)
const Controls=preload("res://scripts/valley_controls.gd")
const HomesteadLife=preload("res://scripts/homestead_life.gd")
const Trails=preload("res://scripts/valley_trails.gd")
const Projects=preload("res://scripts/village_projects.gd")
const Details=preload("res://scripts/valley_details.gd")
var normal_farmer:Texture2D
var work_farmer:Texture2D
var impact_ore:="stone"
var foot_player:=AudioStreamPlayer.new()
var steps_audio:={}
var hand_rest:={}
var work_poses:={}
var counter_keeper:Sprite2D
const Scenery=preload("res://scripts/farm_scenery.gd")
const SeasonEvents=preload("res://scripts/season_events.gd")
const Mines=preload("res://scripts/mine_scenery.gd")
const Mine=preload("res://scripts/mine_progress.gd")
const Rooms=preload("res://scripts/arcade_rooms.gd")
const Schedule=preload("res://scripts/resident_schedule.gd")
const Life=preload("res://scripts/world_life.gd")
const Routes=preload("res://scripts/world_routes.gd")
const Expansion=preload("res://scripts/expansion.gd")
const ExpansionScenery=preload("res://scripts/expansion_scenery.gd")
const Travelers=preload("res://scripts/traveling_residents.gd")
const FishingMotion=preload("res://scripts/fishing_motion.gd")
const Watering=preload("res://scripts/watering_motion.gd")
const SPRING="res://assets/spring/"
const GRID := Vector2i(272,400)
const WIDTH := 11
const HEIGHT := 5
var model
var area := ""
var runner := Sprite2D.new()
var actors := Node2D.new()
var palette:Dictionary={}
var terrain := TileMapLayer.new()
var rail_layer:=Node2D.new()
var crossing_cooldown:=0.0
var impact_at:=Vector2.ZERO
var impact_left:=0.0
var impact_stone:=false
var resource_sprites:={}
var paths := TileMapLayer.new()
var low_detail:=Node2D.new()
var hearth_light:Sprite2D
var tool_sprite:=Sprite2D.new()
var plots := Node2D.new()
var cam := Camera2D.new()
var tex := {}
var targets := {}
var barriers:Array[Rect2]=[]
var npcs := {}
var schedules=Schedule.new()
var mine_beetle:Sprite2D
var lamp_material:ShaderMaterial
var activities:={}
var sleeping_faces:={}
var resident_heads:={}
var traveler_art:={}
var gait:={}
var talking:=""
var hen_sprite:Sprite2D
var leaves:Array[Vector2]=[]
var pos := Vector2.ZERO
var direction := Vector2.DOWN
var elapsed := 0.0
var working := 0.0
var fishing:=FishingMotion.new()
var travel_distance:=0.0
var foot_fade:=0.0
var last_foot:=Vector2.ZERO
var action_tool:=0
var watering:=Watering.new()
var pending_wet:=false
var wet_tile:=""
var tending_at:=Vector2.ZERO
var tending_crop:=-1
var action_duration:=.3
var sitting:=false
var footprints:Array[Vector2]=[]
var last_tide:=false
var step_origin:=Vector2.ZERO
var hover_target:=""
var beyond:=""
var near := ""
var frozen := true
var tool := 0
enum Motion { IDLE, WALK, RUN, TOOL }
var motion:=Motion.IDLE
var shadow:=Sprite2D.new()
var moving := false
var focused := Vector2i(-1,-1)
var cursor_mode := false
var placing:=""
var tint := CanvasModulate.new()
var marks := Node2D.new()
var tilings := {}
var stalks := {}

func setup(state):
	model=state
	Projects.load_art(self)
	HomesteadLife.load_art(self)
	tex["region-Pasture"]=load("res://assets/expansion/pasture.png")
	tex["slate-path"]=load("res://assets/polish/stepping-stones.png")
	add_child(foot_player)
	foot_player.volume_db=-26
	for surface in ["grass","bridge","snow"]:
		steps_audio[surface]=load("res://assets/seasons/"+surface+".wav")
	for id:String in Details.PROPS:work_poses[id]=Details.art("work-"+id.to_lower())
	for id:String in Details.PROPS.values()+["wheel"]:
		tex[id]=Details.art(id)
	for i in 8:tex["pear-"+str(i)]=Details.art("tree-"+str(i))
	for t in ["farm","village","farmer","cottage","stall","sign","bin","chest","mint","hen","iona","oren","crops"]:
		tex[t]=load("res://assets/"+t+".png")
	for fish:Dictionary in Life.FISH:
		tex["catch-"+fish.id]=load("res://assets/field/"+fish.id+".png")
	for id in ["steps-wet","steps-dry","shell-carving"]:
		tex[id]=load("res://assets/field/"+id+".png")
	for id in ["branch","bench","fence","lantern","orchard"]:tex[id]=load("res://assets/"+id+".png")
	for person in model.village.residents:
		var id:String=person.id.to_lower()
		tex[id]=load("res://assets/polish/"+id+".png")
		var face:=AtlasTexture.new()
		face.atlas=tex[id]
		face.region=Rect2(5,3,22,17)
		sleeping_faces[person.id]=face
	for id in ["meadow","paths","homestead","market","chest","bin","hen","oak","cherry","pine","shrub","flowers","sunflowers","rock","rail","lanternpost","banner","paver","crops","bed-wet","bed-dry","hen-walk","library","cistern","kettle","branch","farmer","hoe","packet","can","basket"]:
		tex[id]=load(SPRING+id+".png")
	for id in ["furniture-shadow","hearth-light","village-ground","oak-room","bed","range","bookcase","tea-table","window","pantry","rag-rug","threshold","well","stone-wall","lavender","daisies","tall-grass","stepping-stones","planter-seat","pots","settle","china-cupboard","spinning-wheel","potted-leaves","bedside","hearth-logs","blue-rug","sconce"]:
		tex[id]=load("res://assets/polish/"+id+".png")
	for art in ["mercantile","bakery","bank-plants","dock-lantern","lilies","stone-bridge","stone-deck","item-copper","item-axe","item-pickaxe","item-rod","herbarium","crafts-house","river-lodge","general-counter","pastry-counter","herb-table","farm-crossing","village-ground","grove-ground","farm-deck","village-deck","farm-rail","village-rail"]:
		tex[art]=load("res://assets/valley/"+art+".png")
	for name_ in ["sign-route","sign-hanging","arcade-exterior","crest-wheat","crest-trout","crest-flower","layout-arcade","layout-herbarium","layout-riverlodge","layout-craftshouse","layout-seedloft","layout-bakerloft","sprinkler","garden-pot","broad-hoe","wallpaper-roll","sage-wall"]:
		tex[name_]=load("res://assets/arcade/"+name_+".png")
	for id in model.village.residents:
		resident_heads[id.id]=load("res://assets/arcade/resident-"+id.id.to_lower()+".png")
	for art in ["mine-entrance","mine-lift","mine-mushrooms","mine-crystal","mine-beetle","mine-furnace","mine-dock","mine-supper","mine-floor-0","mine-floor-1","mine-floor-2"]:
		tex[art]=load("res://assets/mine/"+art+".png")
	for region:String in Expansion.NAMES:tex["region-"+region]=load("res://assets/expansion/"+region.to_lower()+".png")
	for id in ["watchlight","pier","dunes","elder-tree","vine-arch","cactus","sand-arch","palm","alpine-lodge","snow-pines","glasshouse","crystals","pool","shell","fish","pottery","honey","chowder","isle-orchard","wagon","marsh-reeds","waterfall","quartz","forest-cap","iceroom","shop"]:
		var path:String="res://assets/expansion/"+id+".png"
		if ResourceLoader.exists(path):tex[id]=load(path)
	for person:String in Travelers.PEOPLE:
		var path:="res://assets/life/"+person.to_lower()+".png"
		traveler_art[person]=load(path if ResourceLoader.exists(path) else HomesteadLife.asset(person.to_lower()))
	for id in ["cast-rod","cast-fish","cast-bobber","cast-splash"]:
		var path:String="res://assets/life/"+id+".png"
		if ResourceLoader.exists(path):tex[id]=load(path)
	add_child(terrain)
	add_child(paths)
	add_child(low_detail)
	add_child(plots)
	add_child(shadow)
	shadow.modulate=Color(.16,.18,.16,.30)
	shadow.hframes=4
	shadow.vframes=4
	actors.y_sort_enabled=true
	add_child(actors)
	add_child(rail_layer)
	add_child(marks)
	marks.z_index=2
	marks.draw.connect(draw_marks)
	add_child(tint)
	runner.texture=tex.farmer
	runner.hframes=4
	runner.vframes=4
	runner.offset=Vector2(0,-18)
	actors.add_child(runner)
	runner.add_child(tool_sprite)
	tool_sprite.visible=false
	tool_sprite.scale=Vector2(.48,.48)
	add_child(cam)
	cam.zoom=Vector2(2,2)
	cam.limit_left=0
	cam.limit_top=0
	cam.limit_right=1152
	cam.limit_bottom=768
	cam.make_current()

func terrain_for(key:String):
	if tilings.has(key):return tilings[key]
	var ts:=TileSet.new()
	ts.tile_size=Vector2i(32,32)
	var source:=TileSetAtlasSource.new()
	source.texture=tex[key]
	source.texture_region_size=ts.tile_size
	ts.add_source(source,0)
	for y in range(24):
		for x in range(36):source.create_tile(Vector2i(x,y))
	tilings[key]=ts
	return ts

func seasonal(kind:String)->ShaderMaterial:
	if not palette.has(kind):
		var material_:=ShaderMaterial.new()
		material_.shader=preload("res://scripts/seasonal_foliage.gdshader")
		material_.set_shader_parameter("canopy",kind=="canopy")
		material_.set_shader_parameter("meadow",kind=="meadow")
		palette[kind]=material_
	var mat:ShaderMaterial=palette[kind]
	mat.set_shader_parameter("season",model.season())
	return mat

func prop(id:String,at:Vector2,k:float=1.0) -> Sprite2D:
	var sp:=Sprite2D.new()
	sp.texture=tex[id]
	if area in Routes.OUTDOORS and id in ["oak","pine","cherry","shrub","flowers","lavender","daisies","tall-grass"]:sp.material=seasonal("canopy")
	sp.scale=Vector2(k,k)
	sp.position=at
	sp.offset=Vector2(0,-sp.texture.get_height()*0.48)
	actors.add_child(sp)
	if area in Routes.OUTDOORS and id in ["library","cistern","kettle","homestead","market","oak","pine","cherry","rock","shrub","chest","bin","banner","rail","lanternpost","well","stone-wall","planter-seat"]:
		var shade:=Sprite2D.new()
		shade.texture=sp.texture
		shade.centered=false
		var sz:=sp.texture.get_size()*k
		# Project each silhouette onto the ground away from the morning sun.
		shade.transform=Transform2D(Vector2(k*.93,0),Vector2(-k*.22,-k*.16),at+Vector2(-sz.x*.46+sz.y*.22,sz.y*.16))
		shade.modulate=Color(.18,.20,.17,.24)
		low_detail.add_child(shade)
	return sp

func ground_detail(id:String,at:Vector2,factor:float):
	var sp:=Sprite2D.new()
	sp.texture=tex[id]
	sp.position=at.round()
	sp.scale=Vector2.ONE*factor
	low_detail.add_child(sp)

func camera_at(at:Vector2)->Vector2:
	if area not in Routes.OUTDOORS:return Vector2(576,356)
	if area!="Farm":return at.round()
	# Hold a composed courtyard view until the farmer nears its margins.
	var anchor:=Vector2(448,350)
	return (at-(at-anchor).clamp(Vector2(-85,-40),Vector2(85,35))).round()

func spot(id:String,art:String,at:Vector2,k:=1.0,solid:=Vector2.ZERO):
	targets[id]=at
	prop(art,at,k)
	if solid!=Vector2.ZERO:barriers.append(Rect2(at-Vector2(solid.x*.5,solid.y),solid))

func spot_furniture(art:String,at:Vector2,scale_:float,footprint:Vector2):
	var shade:=Sprite2D.new()
	shade.texture=tex["furniture-shadow"]
	shade.scale=Vector2(footprint.x/60.0,clampf(footprint.y/28.0,.5,1.45))
	shade.position=at+Vector2(4,-3)
	low_detail.add_child(shade)
	prop(art,at,scale_)
	barriers.append(Rect2(at-Vector2(footprint.x*.5,footprint.y),footprint))

func enter(name_:String,where:Vector2):
	fishing.clear(self)
	travel_distance=0
	foot_fade=0
	working=0
	impact_left=0
	activities.clear()
	watering.age=Watering.DURATION
	pending_wet=false
	tool_sprite.hide()
	placing=""
	mine_beetle=null
	lamp_material=null
	hen_sprite=null
	hearth_light=null
	sitting=false
	footprints.clear()
	step_origin=where
	last_tide=Expansion.low_tide(model)
	hand_rest.clear()
	counter_keeper=null
	cam.offset=Vector2.ZERO
	area=name_
	model.s.area=area
	pos=where
	for a in actors.get_children():
		if a!=runner:actors.remove_child(a);a.queue_free()
	for a in plots.get_children(): plots.remove_child(a);a.queue_free()
	for shelf in [low_detail,rail_layer]:
		for item in shelf.get_children():
			shelf.remove_child(item)
			item.queue_free()
	stalks.clear()
	targets.clear()
	resource_sprites.clear()
	barriers.clear()
	npcs.clear()
	gait.clear()
	talking=""
	cam.zoom=Vector2.ONE*(1.64 if Expansion.NAMES.has(area) else (1.86 if area in Routes.OUTDOORS else 1.68))
	var key:String={"Farm":"meadow","Village":"village-ground","Grove":"grove-ground"}.get(area,"")
	terrain.material=seasonal("meadow") if area=="Farm" else (water_material() if not key.is_empty() else null)
	paths.material=water_material() if area=="Farm" else null
	terrain.clear()
	if not key.is_empty():terrain.tile_set=terrain_for(key)
	paths.clear()
	if area=="Farm":paths.tile_set=terrain_for("farm-crossing")
	if not key.is_empty():
		for y in range(24):
			for x in range(36):
				var cell:=Vector2i(x,y)
				terrain.set_cell(cell,0,cell)
				if area=="Farm":paths.set_cell(cell,0,cell)
		if area in ["Farm","Village"]:
			build_crossing()
		if area!="Grove":
			var rng:=RandomNumberGenerator.new()
			rng.seed=487 if area=="Farm" else 182
			for i in range(104):
				var at:=Vector2(rng.randf_range(10,920),rng.randf_range(40,745))
				if at.x>130 and at.y>145 and at.y<604:continue
				if area=="Farm" and Rect2(338,607,396,99).has_point(at):continue
				if absf(at.y-345)<55 or Routes.wet(area,at) or (area=="Village" and absf(at.x-733)<40):continue
				prop(["oak","cherry","pine","oak"][i%4],at,rng.randf_range(.70,1.14))
				barriers.append(Rect2(at-Vector2(5,13),Vector2(10,12)))

	ExpansionScenery.decorate(self)
	if area=="Farm":
		Scenery.populate(self)
		spot("Cottage","homestead",Vector2(341,284),1,Vector2(139,92))
		spot("Shipping bin","bin",Vector2(493,373),1,Vector2(34,17))
		spot("Storage chest","chest",Vector2(429,373),1,Vector2(28,15))
		spot("Seed market","market",Vector2(681,331),1,Vector2(87,24))
		hen_sprite=prop("hen",Vector2(646,394))
		hen_sprite.texture=tex["hen-walk"]
		hen_sprite.hframes=4
		hen_sprite.offset=Vector2(0,-15)
		for plan in model.home.book.projects:
			if model.s.upgrades.has(plan.id):
				spot(plan.name,plan.id,Vector2(plan.pos[0],plan.pos[1]),1,Vector2(24,12))
		if model.s.tools.get("sprinkler",false):prop("sprinkler",Vector2(638,474),.83)
		refresh_soil()
		for i in range(4):
			var id:="Fallen branch "+str(i+1)
			if model.s.picked.get(id,-1)!=model.s.day:spot(id,"branch",[Vector2(171,366),Vector2(228,402),Vector2(246,294),Vector2(569,272)][i])
		for key_ in model.s.decor:
			var xy=key_.split(",")
			prop(model.s.decor[key_],Vector2(int(xy[0])*32+16,int(xy[1])*32+26))
	elif area=="Village":
		spot("Iona's seed stall","market",Vector2(550,293),.83,Vector2(72,21))
		spot(Routes.NAMES.Mercantile,"mercantile",Routes.DOORS.Mercantile[1],1,Vector2(142,73))
		spot(Routes.NAMES.Bakery,"bakery",Routes.DOORS.Bakery[1]+Vector2(26,0),1,Vector2(119,60))
		targets[Routes.NAMES.Bakery]=Routes.DOORS.Bakery[1]
		for house in [["Herbarium","herbarium",Vector2(-20,0)],["CraftsHouse","crafts-house",Vector2.ZERO],["RiverLodge","river-lodge",Vector2(23,0)]]:
			var entrance:Vector2=Routes.DOORS[house[0]][1]
			spot(Routes.NAMES[house[0]],house[1],entrance+house[2],1,Vector2(112,64))
			targets[Routes.NAMES[house[0]]]=entrance
		var hall:Vector2=Routes.DOORS.Arcade[1]
		spot("Willowbrook Arcade","arcade-exterior",hall,1,Vector2(182,76))
		Rooms.place_sign(self,hall+Vector2(0,-85),"Willowbrook Arcade","",true)
		Rooms.place_sign(self,Vector2(895,370),"Arcade","→")
		Rooms.place_sign(self,Vector2(335,173),"Mercantile","",true)
		Rooms.place_sign(self,Vector2(758,184),"Copper Kettle","",true)
		for entry in [["Herbarium","Fern & Thistle",55],["CraftsHouse","Stave House",55],["RiverLodge","River Lodge",55]]:
			var door:Vector2=Routes.DOORS[entry[0]][1]
			Rooms.place_sign(self,door-Vector2(0,entry[2]),entry[1],"",true)
		Rooms.place_sign(self,Vector2(670,69),"Alderwood","↑")
		ground_detail("paver",Vector2(982,323),1)
		prop("daisies",Vector2(893,303),.87)
		prop("lavender",Vector2(1065,304),.82)
		prop("planter-seat",Vector2(1086,370),.94)
		prop("shrub",Vector2(1120,357),.88)
		targets["Alderwood trail"]=Vector2(733,63)
		prop("lanternpost",Vector2(702,65),.77)
		Scenery.populate_village(self)
		if model.is_fair():
			spot("Seedwake seed fair","market",Vector2(658,405),.72)
		if SeasonEvents.available(model):
			spot("Seasonal market","market",Vector2(652,412),.74,Vector2(65,20))
			Rooms.place_sign(self,Vector2(650,368),SeasonEvents.TITLES[model.season()],"",true)
		for i in range(3):
			var id:="Creek mint "+str(i+1)
			if model.s.picked.get(id,-1)!=model.s.day:spot(id,"mint",Vector2(779+i*45,364+i*10))
	elif area=="Grove":
		Scenery.populate_grove(self)
	elif Expansion.NAMES.has(area):
		ground_detail("region-"+area,Vector2(576,384),1)
		low_detail.move_child(low_detail.get_child(-1),0)
		model.s.expansion.visited[area]=true
	elif area=="Mercantile":
		build_store(false)
	elif area=="Bakery":
		build_store(true)
	elif area=="Arcade":
		Rooms.mall(self)
	elif area.begins_with("Shop:"):
		Rooms.shop(self,area.trim_prefix("Shop:"))
	elif area in ["SlateSpur","FloodedSpur","AlchemyRoom","Pasture"]:
		pass
	elif area=="IceCave":
		ground_detail("mine-floor-2",Vector2(576,356),1)
		if tex.has("iceroom"):ground_detail("iceroom",Vector2(576,400),1)
		for at in [Vector2(360,306),Vector2(458,333),Vector2(760,335),Vector2(804,421)]:
			prop("crystals",at,.72)
		spot("Ice quartz","quartz",Vector2(618,362),.78)
		spot("Ice cave fishing","dock-lantern",Vector2(709,343),.70)
		targets["Leave ice cave"]=Vector2(576,511)
		Rooms.place_sign(self,Vector2(573,262),"Frostpine Ice Cave","",true)
	elif area=="Mine":
		Mines.build(self)
		var shade:=ColorRect.new()
		shade.size=Vector2(1152,768)
		shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
		shade.z_index=4
		lamp_material=ShaderMaterial.new()
		lamp_material.shader=preload("res://scripts/mine_light.gdshader")
		lamp_material.set_shader_parameter("chamber",float(Mine.band(int(model.s.mine.depth))))
		shade.material=lamp_material
		rail_layer.add_child(shade)
	elif Rooms.HOMES.has(area):
		Rooms.home(self,area)
	else:
		ground_detail("oak-room",Vector2(576,356),1)
		if model.s.furnishings.get("home-wall",false):ground_detail("sage-wall",Vector2(576,221),1)
		if model.s.furnishings.get("home-lamp",false):spot_furniture("bedside",Vector2(672,496),.83,Vector2(31,18))
		if model.s.furnishings.get("home-cabinet",false):spot_furniture("china-cupboard",Vector2(650,342),.69,Vector2(40,26))
		ground_detail("rag-rug",Vector2(458,454),1.06)
		ground_detail("blue-rug",Vector2(745,447),1.1)
		hearth_light=Sprite2D.new()
		hearth_light.texture=tex["hearth-light"]
		hearth_light.position=Vector2(708,311)
		var glow:=CanvasItemMaterial.new()
		glow.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
		hearth_light.material=glow
		low_detail.add_child(hearth_light)
		for x in [352,483,622]:ground_detail("window",Vector2(x,229),1)
		ground_detail("pantry",Vector2(804,229),.9)
		for x in [415,550,652]:ground_detail("sconce",Vector2(x,229),.85)
		spot_furniture("bookcase",Vector2(555,303),.90,Vector2(66,23))
		spot_furniture("china-cupboard",Vector2(815,334),1,Vector2(52,29))
		spot_furniture("settle",Vector2(750,430),1,Vector2(106,35))
		spot_furniture("potted-leaves",Vector2(825,440),1,Vector2(19,16))
		spot_furniture("spinning-wheel",Vector2(335,435),1,Vector2(46,39))
		spot_furniture("bedside",Vector2(473,333),1,Vector2(40,23))
		spot_furniture("hearth-logs",Vector2(780,317),.84,Vector2(30,17))
		spot_furniture("tea-table",Vector2(454,443),1,Vector2(108,57))
		spot_furniture("bed",Vector2(403,334),1,Vector2(81,54))
		spot_furniture("range",Vector2(719,302),1,Vector2(87,29))
		ground_detail("threshold",Vector2(577,515),1)
		targets={"Rest until morning":Vector2(405,343),"Hearth kitchen":Vector2(719,315),"Leave cottage":Vector2(577,510)}
	Details.floor_layer(self)
	if area=="Cottage":
		targets["Bedside almanac"]=Vector2(475,339)
		if model.s.expansion.intro and not model.s.expansion.parcel:spot("Seed parcel","packet",Vector2(558,486),.72)
		if model.s.expansion.projects.has("shell-carving"):prop("shell-carving",Vector2(586,272),.42)
		if model.s.expansion.shell_display:prop("shell" if tex.has("shell") else "rock",Vector2(552,269),.54)
	if area=="Farm":
		targets["Cottage step"]=Vector2(377,307)
		spot("Greenhouse","glasshouse" if model.s.expansion.projects.get("greenhouse",false) else "library",Vector2(755,339),.74,Vector2(57,29))
		spot("Orchard hive","chest",Vector2(534,365),.82)
		spot("Herb hive","chest",Vector2(609,362),.82)
	if area=="Village":
		targets["Bridge seat"]=Vector2(141,334)
		spot("Village archive","bookcase",Vector2(844,530),.67)
		if model.s.expansion.projects.get("archive",false):prop("pottery",Vector2(857,514),.71)
		spot("Player market stall","wagon",Vector2(990,453),.79,Vector2(63,16))
		Rooms.place_sign(self,Vector2(1020,447),"Your market stall","",true)
		if Expansion.low_creek(model) and not model.s.expansion.finds.has("creek-pottery"):
			spot("Creek pottery","pottery" if tex.has("pottery") else "rock",Vector2(204,357),.66)
		if int(model.s.mine.dock_stage)>=4:targets["Dock seat"]=Vector2(188,396)
	if area=="Mine" and int(model.s.mine.depth)==9:
		spot("Forgotten passage","crystals",Vector2(526,428),.53)
		Rooms.place_sign(self,Vector2(523,446),"Forgotten passage")
	Mines.outdoor(self)
	Projects.decorate(self)
	if area in ["Grove","Village"]:
		ground_detail(area.to_lower()+"-trail",Vector2(576,384),1)
		low_detail.move_child(low_detail.get_child(-1),0)
	HomesteadLife.decorate(self)
	var legacy_residents:bool=area not in ["Cottage","Mine","IceCave","SlateSpur","FloodedSpur","AlchemyRoom","Pasture"] and not Expansion.NAMES.has(area) and not area.begins_with("Shop:")
	var regional:=Travelers.PEOPLE.keys().filter(func(id):return Travelers.uses_zone(model,id,area))
	if legacy_residents or not regional.is_empty():schedules.setup(area,self)
	if legacy_residents:
		for person in model.village.residents:
			var id:String=person.id
			var sp:=Sprite2D.new()
			sp.texture=tex[id.to_lower()]
			sp.hframes=3
			sp.offset=Vector2(0,-18)
			actors.add_child(sp)
			npcs[id]=sp
	for id:String in regional:
		var sp:=Sprite2D.new()
		sp.texture=traveler_art[id]
		sp.offset.y=-sp.texture.get_height()*.5
		actors.add_child(sp)
		npcs[id]=sp
	refresh_people()
	runner.position=pos
	if blocked(pos):
		# Older slots can lie inside the new footprint. Use the closest walkable point.
		var found:=false
		for distance in range(4,152,4):
			for side in [Vector2.DOWN,Vector2.UP,Vector2.RIGHT,Vector2.LEFT]:
				var candidate:Vector2=pos+side*distance
				if not blocked(candidate):
					pos=candidate
					found=true
					break
			if found:break
		if blocked(pos):
			var landing:Dictionary={"Farm":Vector2(871,334),"Village":Vector2(447,339),"Grove":Vector2(733,703)}
			pos=landing.get(area,Vector2(575,479))
		runner.position=pos
	cam.position=camera_at(pos)
	cam.force_update_scroll()
	update_mine(0)
	update_target()
	marks.queue_redraw()

func water_material()->ShaderMaterial:
	var water:=ShaderMaterial.new()
	water.shader=preload("res://scripts/river.gdshader")
	water.set_shader_parameter("region",Routes.OUTDOORS.find(area))
	return water

func build_crossing():
	var id:="farm" if area=="Farm" else "village"
	var left:=944.0 if area=="Farm" else 0.0
	barriers.append(Rect2(left,306,208,9))
	barriers.append(Rect2(left,354,208,9))
	ground_detail(id+"-deck",Vector2(576,338),1)
	var rail:=Sprite2D.new()
	rail.texture=tex[id+"-rail"]
	rail.position=Vector2(576,338)
	rail_layer.add_child(rail)
	var origin:=931 if area=="Farm" else 228
	for y in [100,179,263,391,468,552,676]:
		var bank:=Routes.west_bank(y) if area=="Farm" else Routes.east_bank(y)
		prop("bank-plants",Vector2(bank+(-14 if area=="Farm" else 14),y),.72)
	prop("dock-lantern",Vector2(origin,318),.96)
	prop("dock-lantern",Vector2(origin,355),1)
	spot("Fish the creek","dock-lantern",Vector2(origin,432),.82)
	var sign_at:=Vector2(origin-65 if area=="Farm" else origin+65,283)
	var farm_side:=area=="Farm"
	Rooms.place_sign(self,sign_at,"Willowbrook" if farm_side else "Farmlands","→" if farm_side else "←")
	targets["Bridge to Willowbrook" if farm_side else "Bridge to Hearthvale"]=sign_at+Vector2(0,15)

func build_store(bakery:bool):
	ground_detail("oak-room",Vector2(576,356),1)
	for x in [379,535,758]:ground_detail("window",Vector2(x,228),1)
	for x in [447,652,811]:ground_detail("sconce",Vector2(x,229),1)
	ground_detail("blue-rug" if bakery else "rag-rug",Vector2(566,425),1)
	ground_detail("threshold",Vector2(577,515),1)
	spot_furniture("china-cupboard",Vector2(350,337),1,Vector2(54,45))
	spot_furniture("pastry-counter" if bakery else "general-counter",Vector2(566,344),1,Vector2(133,35))
	spot_furniture("range" if bakery else "bookcase",Vector2(746,313),1,Vector2(75,26))
	spot_furniture("settle",Vector2(768,431),.9,Vector2(94,30))
	spot_furniture("pots",Vector2(351,420),1,Vector2(33,24))
	targets["Leave shop"]=Vector2(577,510)
	targets["Bakery counter" if bakery else "Mercantile counter"]=Vector2(565,367)
	if bakery:targets["Hearth kitchen"]=Vector2(744,327)
	targets["Pip’s Attic" if bakery else "Iona’s Seed Loft"]=Vector2(798,351)
	Rooms.place_sign(self,Vector2(793,302),"Upstairs","↑",true)

func build_stone_bridge():
	ground_detail("stone-deck",Vector2(454,513),1)
	barriers.append(Rect2(411,483,86,9))
	barriers.append(Rect2(411,517,86,9))
	var parapet:=Sprite2D.new()
	parapet.texture=tex["stone-bridge"]
	parapet.position=Vector2(454,528)
	rail_layer.add_child(parapet)

func occupation(sprite:Sprite2D,id:String,working_here:bool):
	var pose:Sprite2D=sprite.get_node_or_null("WorkingPose")
	if not working_here or not work_poses.has(id):
		if pose!=null:pose.hide()
		sprite.self_modulate.a=1.0
		return
	if pose==null:
		pose=Sprite2D.new()
		pose.name="WorkingPose"
		pose.texture=work_poses[id]
		pose.hframes=3
		pose.offset=Vector2(0,-21)
		sprite.add_child(pose)
	pose.show()
	sprite.self_modulate.a=0.0
	var close_enough:bool=talking==id or (pos.distance_to(sprite.position)<49)
	var prior:Dictionary=hand_rest.get(id,{"near":false,"since":elapsed})
	if prior.near!=close_enough:
		prior={"near":close_enough,"since":elapsed}
	hand_rest[id]=prior
	var age:float=elapsed-float(prior.since)
	if close_enough:pose.frame=1 if age<.35 else 2
	else:pose.frame=1 if fmod(age+float(id.length()),3.1)>.98*2.1 else 0
	pose.flip_h=close_enough and pos.x<sprite.position.x

func refresh_people():
	if is_instance_valid(counter_keeper):occupation(counter_keeper,preload("res://scripts/arcade_stock.gd").STORES[area.trim_prefix("Shop:")].keeper,true)
	if npcs.is_empty():return
	activities.clear()
	for id:String in npcs:
		var sprite:Sprite2D=npcs[id]
		var data:Dictionary=schedules.sample(model,id)
		sprite.visible=not data.is_empty()
		if data.is_empty():
			targets.erase(id)
			continue
		sprite.position=data.position
		occupation(sprite,id,not data.moving and not data.activity in ["Sleeping","Having breakfast","Having supper by the dock"] and not data.activity.contains("Reading"))
		if data.activity=="Sleeping" and area not in Routes.OUTDOORS:
			sprite.hframes=1
			sprite.vframes=1
			sprite.texture=sleeping_faces[id]
			sprite.position=data.position+Vector2(0,-(65 if area=="CraftsHouse" else 68))
			sprite.rotation=0
			sprite.offset=Vector2.ZERO
			targets.erase(id)
			activities[id]=data.activity
			continue
		var state:Dictionary=gait.get(id,{"pos":data.position,"dist":0.0,"row":0})
		var distance:float=state.pos.distance_to(data.position)
		var walking:bool=data.moving and distance>.015 and talking!=id
		if walking:
			var direction_:Vector2=data.direction
			state.row=(1 if direction_.x>0 else 3) if absf(direction_.x)>absf(direction_.y) else (2 if direction_.y<0 else 0)
			state.dist+=minf(distance,25)
		state.pos=data.position
		gait[id]=state
		if Travelers.PEOPLE.has(id):
			animate_traveler(sprite,id,data,state,walking)
			continue
		sprite.texture=resident_heads[id]
		sprite.hframes=8
		sprite.vframes=4
		sprite.offset=Vector2(0,-21)
		sprite.position=data.position.round()
		sprite.flip_h=false
		var seconds:=elapsed+float(id.unicode_at(0))*.11
		var activity:String=data.activity
		var using_prop:bool=not walking and (activity.begins_with("Fishing") or activity.contains("counter") or activity.contains("breakfast") or activity.contains("supper") or activity.begins_with("Reading"))
		var row:int=state.row if talking!=id else 0
		var frame:int=6+int(fmod(seconds,3.4)<.48)
		if walking:frame=int(state.dist/3.0)%6
		elif using_prop or talking==id:frame=6+int(fmod(seconds*3.5,2.0)>=1.0)
		sprite.frame=row*8+frame
		sprite.rotation=sin(seconds*4.0)*.039 if using_prop or talking==id else 0
		targets[id]=sprite.position
		activities[id]=activity

func animate_traveler(sprite:Sprite2D,id:String,data:Dictionary,state:Dictionary,walking:bool):
	var step:=float(state.dist)*PI/9.0
	var lift:=absf(sin(step))*2.2 if walking else 0.0
	var heading:Vector2=data.get("direction",Vector2.ZERO)
	if talking==id:sprite.flip_h=pos.x<data.position.x
	elif walking and absf(heading.x)>.15:sprite.flip_h=heading.x<0
	sprite.position=(data.position+Vector2(0,-lift)).round()
	sprite.rotation=sin(step)*.065 if walking else sin(elapsed*2.3)*.018
	var scale_factor:float=.72 if id in ["Maelin","Fenn","Heath"] else 1.0
	sprite.scale=Vector2(1+lift*.012,1-lift*.015)*scale_factor
	targets[id]=data.position
	activities[id]=data.activity

func draw_resident_actions():
	for id:String in activities:
		if not gait.has(id) or not npcs[id].visible:continue
		var action:String=activities[id]
		var sprite:Sprite2D=npcs[id]
		var traveling:bool=Travelers.PEOPLE.has(id)
		if not traveling and (sprite.hframes!=8 or sprite.frame%8<6):continue
		if traveling and (schedules.sample(model,id).get("moving",false)):continue
		var sway:=sin(elapsed*4.0)*3.0
		var at:=sprite.position+Vector2(6,-19+sway)
		var icon:=""
		if action.begins_with("Fishing"):
			var cast:=sin(TAU*fmod(elapsed,3.8)/3.8)
			at+=Vector2(cast*6,-maxf(0,cast)*9)
			var end:=at+Vector2(-15,8)
			marks.draw_line(end,end+Vector2(-9,12),Color(.86,.83,.67,.78),1)
			icon="item-rod"
		elif action.contains("counter"):icon="packet"
		elif action.contains("breakfast") or action.contains("supper"):icon="basket"
		elif action.begins_with("Reading"):icon="bookcase"
		elif action.contains("staves"):icon="branch"
		elif action.contains("herbs") or action.contains("mint"):
			at+=Vector2(3,8.0*absf(sin(elapsed*2.2)))
			icon="mint"
		if not action.contains("Sleeping") and not action.contains("breakfast") and not action.contains("supper"):
			icon=Details.PROPS.get(id,icon)
		var pose:Sprite2D=sprite.get_node_or_null("WorkingPose")
		if pose!=null and pose.visible:continue
		if icon!="":
			marks.draw_texture_rect(tex[icon],Rect2(at,Vector2(15,15)),false)

func tile_key(t:Vector2i)->String:return "%d,%d"%[t.x,t.y]
func tile_at(at:Vector2)->Vector2i:return Vector2i(((at-Vector2(GRID))/32.0).floor())
func in_field(t:Vector2i)->bool:return area=="Farm" and Rect2i(0,0,WIDTH,HEIGHT).has_point(t)

func refresh_soil():
	for key in model.s.soil:
		var v=key.split(",")
		var t:=Vector2i(int(v[0]),int(v[1]))
		var p:Dictionary=model.s.soil[key]
		if not stalks.has(key):
			var bed:=Sprite2D.new()
			bed.centered=false
			bed.position=Vector2(GRID+t*32)
			plots.add_child(bed)
			var sp:=Sprite2D.new()
			sp.texture=tex.crops;sp.hframes=4;sp.vframes=12;sp.position=bed.position+Vector2(16,30);sp.offset=Vector2(0,-16);actors.add_child(sp)
			stalks[key]=[bed,sp]
		var pair:Array=stalks[key]
		pair[0].texture=tex["bed-wet"] if p.wet else tex["bed-dry"]
		pair[1].visible=p.crop>=0
		if p.crop>=0:
			var days:float=model.crops[int(p.crop)].days
			pair[1].frame=int(p.crop)*4+mini(3,int(float(p.age)*3/days))

func blocked(at:Vector2)->bool:
	if area=="Pasture" and not Rect2(113,194,924,516).has_point(at):return true
	if area=="Mine":
		if Mines.blocked(int(model.s.mine.depth),at):return true
	elif area not in Routes.OUTDOORS:
		if Rooms.FLOOR_WALKS.has(area):
			if not Rooms.walkable(area,at):return true
		elif not Rect2(301,283,550,239).has_point(at):return true
	elif ExpansionScenery.wet(area,at):return true
	elif Routes.wet(area,at):
		var on_dock:bool=area=="Village" and int(model.s.mine.dock_stage)>=4 and Rect2(146,373,65,29).has_point(at)
		if not on_dock:return true
	for b in barriers:
		if b.has_point(at):return true
	return false

func update_target():
	beyond=""
	hover_target=clicked_interaction(get_global_mouse_position()) if cursor_mode else ""
	near=""
	var dist:=57.0
	for id in targets:
		var d:=pos.distance_to(targets[id])
		if id.ends_with("counter"):d-=14.0
		if d<dist:dist=d;near=id
		elif cursor_mode and d>=60 and d<115 and get_global_mouse_position().distance_to(Vector2(targets[id])-Vector2(0,10))<17:beyond=id

func tick(dt:float):
	elapsed+=dt
	HomesteadLife.update(self)
	if area=="Coast" and resource_sprites.has("tide-steps"):
		resource_sprites["tide-steps"].texture=tex["steps-dry" if Expansion.steps_exposed(model) else "steps-wet"]
	working=maxf(0,working-dt)
	impact_left=maxf(0,impact_left-dt)
	crossing_cooldown=maxf(0,crossing_cooldown-dt)
	watering.age=minf(Watering.DURATION,watering.age+dt)
	if pending_wet and watering.age>=Watering.IMPACT:
		pending_wet=false
		refresh_soil()
	if stalks.has(wet_tile):
		var plant:Sprite2D=stalks[wet_tile][1]
		var bend:=maxf(0.0,1.0-absf(watering.age-.48)*5.0)
		plant.rotation=.16*watering.side*bend
	var origin_pos:=pos
	foot_fade=maxf(0,foot_fade-dt)
	var velocity:=Vector2(float(Controls.held(model,"Right"))-float(Controls.held(model,"Left")),float(Controls.held(model,"Down"))-float(Controls.held(model,"Up")))
	velocity+=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if fishing.phase in ["catch","miss"] and velocity.length_squared()>.01:fishing.clear(self)
	if sitting and velocity.length_squared()>.01:sitting=false
	if not sitting and (watering.age<.11 or impact_left>.18):velocity=Vector2.ZERO
	moving=velocity.length_squared()>.01
	if moving:
		if watering.age>=.6:direction=velocity.normalized()
		var step:=velocity.normalized()*(145 if Controls.held(model,"Run") else 93)*dt
		for delta in [Vector2(step.x,0),Vector2(0,step.y)]:
			var at:Vector2=(pos+delta).clamp(Vector2(12,25),Vector2(1140,753))
			if not blocked(at):pos=at
	if area=="Coast" and last_tide!=Expansion.low_tide(model):
		last_tide=Expansion.low_tide(model)
		if resource_sprites.has("shell-on-beach"):resource_sprites["shell-on-beach"].visible=last_tide
	if moving and area in Routes.OUTDOORS and model.weather(model.s.day)=="Showers" and pos.distance_to(step_origin)>13:
		footprints.append(pos)
		if footprints.size()>8:footprints.pop_front()
		step_origin=pos
	if crossing_cooldown<=0:
		var side:=Routes.edge(area,pos,velocity)
		if side!="":
			crossed.emit(area,side,pos)
			return
	var distance:=origin_pos.distance_to(pos)
	var old_step:=floori(travel_distance/9.5)
	travel_distance+=distance
	moving=distance>.01
	if moving and floori(travel_distance/9.5)>old_step:
		last_foot=pos-direction*3+direction.orthogonal()*(3 if old_step%2==0 else -3)
		foot_fade=.23
		if model.s.sound:
			var surface:="snow" if area=="Frost" or (area in Routes.OUTDOORS and model.season()>=6) else "grass"
			if area in ["Farm","Village"] and pos.y>314 and pos.y<354 and ((area=="Farm" and pos.x>943) or (area=="Village" and pos.x<186)):surface="bridge"
			foot_player.stream=steps_audio[surface]
			foot_player.pitch_scale=1.06 if old_step%2 else .95
			foot_player.play()
	var row:=direction_row(direction)
	var pouring:=watering.age<Watering.DURATION
	motion=Motion.TOOL if working>0 or pouring else (Motion.RUN if moving and Controls.held(model,"Run") else (Motion.WALK if moving else Motion.IDLE))
	var farmer_frame:=0
	match motion:
		Motion.WALK:farmer_frame=floori(travel_distance/5.3)%4
		Motion.RUN:farmer_frame=[0,2,1,3][floori(travel_distance/7.4)%4]
		Motion.TOOL:farmer_frame=(1 if working>.13 else 2) if not pouring else 0
	if pouring:
		farmer_frame=2 if watering.age>=.18 and watering.age<.56 else 1
	if impact_left>0:
		direction=(impact_at-pos).normalized()
		row=direction_row(direction)
		farmer_frame=1 if impact_left>.18 else 2
	if normal_farmer!=null:
		runner.texture=work_farmer if (pouring or impact_left>0 or working>0) else normal_farmer
		if runner.texture==work_farmer:
			farmer_frame=(2 if impact_left>.18 else 3) if impact_left>0 else (1 if pouring and watering.age>.18 and watering.age<.58 else 0)
	runner.frame=row*4+farmer_frame
	shadow.texture=runner.texture
	shadow.frame=runner.frame
	shadow.transform=Transform2D(Vector2(.8,0),Vector2(-.27,-.17),pos+Vector2(4,1))
	var stride:=absf(sin(travel_distance*PI/9.5)) if moving else 0.0
	var rise:=stride*(2.5 if motion==Motion.RUN else 1.5)
	runner.position=(pos+Vector2(0,4 if sitting else -rise-sin(working/action_duration*PI)*3)).round()
	runner.rotation=move_toward(runner.rotation,direction.x*.075 if motion==Motion.RUN else 0.0,dt*.8)
	tool_sprite.visible=working>0 or pouring
	if pouring:
		tool_sprite.texture=tex.can
		tool_sprite.z_index=0 if row==3 else 1
		watering.pose(tool_sprite,runner.position)
	elif working>0:
		tool_sprite.z_index=0
		tool_sprite.texture=tex["broad-hoe"] if action_tool==0 and model.s.tools.get("broad-hoe",false) else tex[["hoe","packet","can","basket"][action_tool]]
		tool_sprite.position=(direction*13+Vector2(0,-14)).round()
		tool_sprite.rotation=-.65+1.35*(1.0-working/action_duration)
		tool_sprite.flip_h=direction.x<0
	fishing.update(self,dt,false)
	cam.offset=Vector2(0,-1) if impact_left>.12 and impact_left<.17 and not model.s.expansion.projects.get("steady-camera",false) else Vector2.ZERO
	cam.position=camera_at(pos)
	model.s.x=pos.x
	model.s.y=pos.y
	refresh_people()
	if hen_sprite!=null:
		var phase:=fmod(elapsed,10.0)
		var a:float=(floor(elapsed/10.0)*6.0+minf(phase,6.0))*.33
		var at:=Vector2(654+sin(a)*14,392+sin(a*1.4)*6)
		hen_sprite.position=at
		hen_sprite.flip_h=cos(a)<0
		hen_sprite.frame=1+int(elapsed*5)%2 if phase<6 else (3 if fmod(phase,1.25)<.55 else 0)
		targets["Bramble the hen" if model.s.hen else "Meet Bramble"]=at
	if hearth_light!=null:
		hearth_light.modulate.a=.78+sin(elapsed*8.0)*.09+sin(elapsed*17.0)*.06
	update_mine(dt)
	Mines.update_supper(self)
	update_target()
	update_focus()
	var dusk:float=clampf((float(model.s.time)-965.0)/240.0,0,1)
	var seasonal:Array=[Color.WHITE,Color("#fff3e5"),Color("#fff1c9"),Color("#d1e7dd"),Color("#f8d4a2"),Color("#e4c5b2"),Color("#d9e8f1"),Color("#cde3ed")]
	tint.color=(Color.WHITE if area not in Routes.OUTDOORS else seasonal[model.season()]).lerp(Color("#8188af"),dusk*.74)
	marks.queue_redraw()

func direction_row(from:Vector2)->int:
	if absf(from.x)>absf(from.y):return 1 if from.x<0 else 2
	return 3 if from.y<0 else 0

func cast_point(site:String)->Vector2:
	match site:
		"river":
			return Vector2(Routes.west_bank(pos.y)+34,pos.y+4) if area=="Farm" else Vector2(Routes.east_bank(pos.y)-34,pos.y+4)
		"pond":return Vector2(410,429)
		"mine":return Vector2(752,305) if area=="FloodedSpur" else Vector2(754,296)
		"ice-cave":return Vector2(740,301)
	if Expansion.FISHING.has(area):
		var anchor:Vector2=Expansion.FISHING[area][1]
		return Vector2(anchor.x,minf(anchor.y-45,309))
	return pos+Vector2(0,-47)

func update_focus():
	focused=tile_at(get_global_mouse_position() if cursor_mode else pos+direction*(32 if longer_reach() else 19))

func clicked_interaction(at:Vector2)->String:
	var best:=""
	var distance:=32.0
	for id in targets:
		var anchor:Vector2=targets[id]
		if pos.distance_to(anchor)>60:continue
		var d:=at.distance_to(anchor-Vector2(0,10))
		if d<distance:
			best=id
			distance=d
	return best

func longer_reach()->bool:
	return (tool==2 and model.s.tools.get("long-can",false)) or (tool==0 and model.s.tools.get("broad-hoe",false))

func act(use_mouse:bool):
	var at:=get_global_mouse_position() if use_mouse else pos+direction*(32 if longer_reach() else 19)
	var t:=tile_at(at)
	if use_mouse and pos.distance_to(at)>(106 if longer_reach() and in_field(t) else 73):
		step_message.emit("Walk closer to reach that spot.");return
	if placing!="":
		var cell:=Vector2i((at/32).floor())
		var key:=tile_key(cell)
		if can_place(at) and model.change(placing,-1):
			model.s.decor[key]=placing
			var message:="Placed "+str(model.item_name(placing))+"."
			enter(area,pos);step_message.emit(message)
		else:step_message.emit("Choose a clear patch of lawn near you.")
		return
	if in_field(t):
		if tool==2 and watering.age<Watering.DURATION:return
		var key:=tile_key(t)
		var old_plot:Dictionary=model.s.soil.get(key,{})
		tending_crop=int(old_plot.get("crop",-1))
		tending_at=Vector2(GRID+t*32)+Vector2(16,21)
		if pos.distance_to(tending_at)>2:direction=(tending_at-pos).normalized()
		var msg:String=model.work(key,tool)
		if model.s.expansion.intro and msg.begins_with(["Soil turned","Planted","Watered","Harvested"][tool]):
			model.s.expansion.lessons[str(tool)]=true
		if msg.begins_with("Harvested"):model.s.expansion.first_harvest=true
		if tool==2 and msg.begins_with("Watered"):
			var landing:=Vector2(GRID+t*32)+Vector2(16,21)
			var facing:Vector2=(landing-pos).normalized()
			if facing.length_squared()>.01:direction=facing
			watering.start(pos,landing,direction)
			wet_tile=key
			pending_wet=true
			working=0
		elif tool!=2 and msg.begins_with(["Soil turned","Planted","Watered","Harvested"][tool]):
			action_duration=[.30,.22,.30,.40 if tending_crop in [0,4] else .26][tool]
			working=action_duration
			action_tool=tool
			watering.age=Watering.DURATION
			pending_wet=false
			refresh_soil()
		step_message.emit(msg)
	elif use_mouse:
		var id:=clicked_interaction(at)
		if id!="":used.emit(id)
	elif near!="":used.emit(near)
	else:step_message.emit("The planting beds are south of the cottage path.")

func can_place(at:Vector2)->bool:
	var cell:=Vector2i((at/32).floor());var center:=Vector2(cell*32)+Vector2(16,16)
	if area!="Farm" or pos.distance_to(center)>73 or model.s.decor.has(tile_key(cell)):return false
	if not Rect2(96,275,790,390).has_point(center) or Rect2(240,375,408,220).has_point(center) or blocked(center):return false
	for target in targets.values():
		if center.distance_to(target)<36:return false
	return true
func draw_marks():
	Details.scenery(self)
	draw_resident_actions()
	fishing.draw(self)
	if foot_fade>0 and area in Routes.OUTDOORS and not Routes.wet(area,last_foot):
		var p:=1.0-foot_fade/.23
		var color:=Color(.85,.73,.55,foot_fade*1.35)
		for i in range(3):
			var fleck:=last_foot-direction*p*(3+i)+Vector2(i-1,-sin(p*PI)*(i+2))
			marks.draw_rect(Rect2(fleck.round(),Vector2(1,1)),color)
	if area=="Village" and model.s.expansion.intro and model.s.day>=1 and not model.s.expansion.oren_note and model.s.time>=850 and model.s.time<1150:
		for i in range(12):
			var foot:=Vector2(190+i*5,338+i*1.5)+(Vector2(0,3) if i%2==0 else Vector2.ZERO)
			marks.draw_rect(Rect2(foot,Vector2(3,5)),Color(.28,.23,.16,.31))
	if Expansion.FISHING.has(area):
		for i in range(39):
			var x:=fposmod(i*79+elapsed*(3+i%4),752)
			var y:=fposmod(i*83+sin(elapsed+i)*3,372)
			if ExpansionScenery.wet(area,Vector2(x,y)) and y>138:
				var opacity:=.16+.12*sin(elapsed*.9+i)
				marks.draw_line(Vector2(x,y),Vector2(x+8+i%12,y),Color(.76,.92,.90,opacity),1)
	if area=="Desert" and model.s.expansion.projects.get("oasis",false):
		var channel:=PackedVector2Array([Vector2(572,412),Vector2(554,440),Vector2(530,447),Vector2(498,472),Vector2(487,506)])
		marks.draw_polyline(channel,Color("#735242"),8)
		marks.draw_polyline(channel,Color("#598d83"),5)
		for i in range(8):
			var progress:=fposmod(elapsed*.32+i*.29,4.0)
			var segment:=floori(progress)
			var ripple:=channel[segment].lerp(channel[segment+1],progress-segment)
			marks.draw_line(ripple,ripple+Vector2(2,-1),Color("#b7d8b2"),1)
	if area=="Frost":
		for i in range(16):
			var steam:=Vector2(606+sin(i*7+elapsed)*8,405-fposmod(i*4+elapsed*9,38))
			marks.draw_circle(steam,1.5+i%3,Color(.91,.96,1,.12))
	if area=="Marsh" and model.weather(model.s.day)=="Showers":
		var ripple:=fposmod(elapsed*.5,1.0)
		marks.draw_arc(Vector2(688,329),5+ripple*24,0,TAU,20,Color(.78,.91,.73,1-ripple),1)
	for index in range(footprints.size()):
		var foot:=footprints[index]+Vector2(-2 if index%2==0 else 2,0)
		marks.draw_rect(Rect2(foot,Vector2(3,5)),Color(.23,.17,.13,(index+1)*.029))
	if area=="Cottage" and model.weather(model.s.day)=="Showers":
		for i in range(18):
			var window:=Vector2([352,483,622][i%3],209)
			var p:=window+Vector2((i*13)%27-13,fmod(i*7+elapsed*25,28))
			marks.draw_line(p,p+Vector2(-1,4),Color(.65,.82,.88,.52),1)
	if area=="Mine":
		var band:=Mine.band(int(model.s.mine.depth))
		if band==2:
			for i in range(9):
				var ripple:=Vector2(712+fmod(i*31.0+elapsed*3,104),254+fmod(i*14.0+elapsed*1.4,70))
				marks.draw_line(ripple,ripple+Vector2(7+i%4,0),Color(.43,.75,.76,.24),1)
		elif band==1:
			for i in range(14):
				var spore:=Vector2(327+fmod(i*72+elapsed*3.0,500),248+fmod(i*37+elapsed*4.0,218))
				marks.draw_circle(spore,1.2,Color(.7,.54,1.0,.16+.18*absf(sin(elapsed+i))))
	if placing!="":
		var at:=get_global_mouse_position() if cursor_mode else pos+direction*19
		var origin:=(at/32).floor()*32
		marks.draw_rect(Rect2(origin,Vector2(32,32)),Color("#dcf3ac") if can_place(at) else Color("#e29482"),false,2)
		marks.draw_texture(tex[placing],origin+Vector2(-4,-13),Color(1,1,1,.65))
	if area in Routes.OUTDOORS:
		for i in range(19):
			var x:=fmod(i*83+elapsed*(4+i%3),1120.0)
			var y:=fmod(i*51+sin(elapsed+i)*7,740.0)
			marks.draw_rect(Rect2(x,y,2,1),Color(1,.94,.74,.65))
		if model.weather(model.s.day)=="Showers":
			for i in range(105):
				var x:=fmod(i*97-elapsed*42+23040,1152)
				var y:=fmod(i*71+elapsed*134,768)
				marks.draw_line(Vector2(x,y),Vector2(x-2,y+6),Color(.8,.93,.99,.5),1)
	if area=="Farm" and model.s.expansion.intro and model.s.expansion.lessons.size()<3:
		for x in range(3):
			var training:=Rect2(Vector2(GRID+Vector2i(x,0)*32)+Vector2(3,3),Vector2(26,26))
			marks.draw_rect(training,Color(1,.86,.54,.34+.12*sin(elapsed*2)),false,1)
	if in_field(focused):
		var box:=Rect2(Vector2(GRID+focused*32)+Vector2(1,1),Vector2(30,30))
		var plot:Dictionary=model.s.soil.get(tile_key(focused),{})
		var valid:bool=pos.distance_to(box.get_center())<(107 if longer_reach() else 74)
		var crop:=int(plot.get("crop",-1))
		var suitable:=plot.is_empty() if tool==0 else not plot.is_empty()
		if tool==1:suitable=suitable and crop<0
		if tool==3:suitable=crop>=0 and int(plot.get("age",0))>=int(model.crops[crop].days) if crop>=0 else false
		var rim:=Color("#c5eb93") if valid and suitable else Color("#c4a58c")
		for corner in [Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Vector2.ONE]:
			var point:Vector2=box.position+box.size*corner
			var inward:Vector2=Vector2.ONE-2*corner
			marks.draw_line(point,point+Vector2(inward.x*6,0),rim,1)
			marks.draw_line(point,point+Vector2(0,inward.y*6),rim,1)
	if watering.age<Watering.DURATION:
		watering.draw_water(marks)
	if impact_left>0:
		var facing:float=1 if impact_at.x>=pos.x else -1
		var arc:float=1.0-impact_left/.34
		var tool_art:Texture2D=tex.get("item-pickaxe" if impact_stone else "item-axe")
		if tool_art!=null:
			marks.draw_set_transform(pos+Vector2(facing*16,-19),facing*(-.85+1.88*smoothstep(0,.53,arc)),Vector2(facing,1))
			marks.draw_texture_rect(tool_art,Rect2(-10,-11,24,24),false)
			marks.draw_set_transform(Vector2.ZERO)
		for i in range(8):
			if arc<.48:break
			var progress:=(arc-.48)/.52
			var delta:=Vector2(cos(i*2.4)*progress*18,-sin(progress*PI)*(7+i%4))
			var color:Color={"copper":Color("#e9a072"),"iron-ore":Color("#9cb5c4"),"moonstone":Color("#bec4ff"),"coal":Color("#666374")}.get(impact_ore,Color("#e3dec6")) if impact_stone else Color("#dca975")
			marks.draw_rect(Rect2(impact_at+delta+Vector2(0,-9),Vector2(2,2)),color)
	if working>0:
		var p:=tending_at
		for i in range(5):
			var progress:=1.0-working/action_duration
			var v:=Vector2.from_angle(i*1.26)*progress*10+Vector2(0,-sin(progress*PI)*(5+i))
			marks.draw_rect(Rect2(p+v,Vector2(2,2)),Color("#b88152") if action_tool in [0,3] else Color("#ecd6a5"))
		if action_tool==3 and tending_crop>=0:
			var lift:=sin(PI*working/action_duration)*12
			marks.draw_circle(p+Vector2(0,-lift-4),3,Color(model.crops[tending_crop].color))
	if area=="Mine":
		for i in range(Mine.nodes(int(model.s.mine.depth)).size()):
			var key:="mine-node:"+str(i)
			if not targets.has(key):continue
			var hits:int=int(model.s.mine.nodes.get("%d:%d"%[model.s.mine.depth,i],0))
			if hits<1:continue
			var at:Vector2=targets[key]-Vector2(5,15)
			marks.draw_polyline(PackedVector2Array([at,at+Vector2(5,3),at+Vector2(3,4+hits*2),at+Vector2(6+hits,5+hits*3)]),Color("#32283d"),1+minf(1,hits*.3))
			if hits>1:marks.draw_line(at+Vector2(4,4),at+Vector2(9+hits,0),Color("#493d48"),1)
	if area=="Grove":
		for id:String in Life.NODES:
			if not targets.has("resource:"+id):continue
			var hits:=int(model.s.resources.get(id,{}).get("hits",0))
			if hits>0:
				var at:Vector2=targets["resource:"+id]-Vector2(5,10)
				marks.draw_line(at,at+Vector2(3+hits*2,2),Color("#cd9c65") if Life.NODES[id][5]=="wood" else Color("#403c44"),2)


func show_resource_nodes():
	for id:String in Life.NODES:
		var spec:Array=Life.NODES[id]
		if spec[0]!=area:continue
		var at:Vector2=spec[1]
		if id=="nursery" and not model.s.resources.has(id):
			spot("Plant alder seed","pots",at,.75)
			continue
		var days:=Life.remaining(model,id)
		if days>0:
			if spec[5]=="wood":
				if days<=4 or id=="nursery":
					prop(spec[2],at,.24 if days>2 else .46)
				else:prop("hearth-logs",at,.45)
			continue
		targets["resource:"+id]=at
		resource_sprites[id]=prop(spec[2],at,.86 if spec[5]=="wood" else .99)
		barriers.append(Rect2(at-Vector2(10,9),Vector2(20,12)))

func node_label(key:String)->String:
	if npcs.has(key):return "Talk to "+key
	if key in ["Fish the creek","Fish Alderwood Pond","travel:fish"]:return "Cast line"
	if key.begins_with("shop:"):return "Enter "+key.trim_prefix("shop:")
	if key.begins_with("travel:"):
		match key:
			"travel:landmark":return Expansion.LANDMARKS[area][0]
			"travel:find":return Expansion.DISCOVERIES[area][2]
			"travel:fish":return "Cast your line"
			"travel:rest":return "Sit and listen"
	if key.begins_with("mine-node:"):
		var node:Dictionary=Mine.nodes(int(model.s.mine.depth))[int(key.get_slice(":",1))]
		return "Mine "+model.item_name(node.ore)
	var spec:Array=Life.NODES.get(key.trim_prefix("resource:"),[])
	if spec.is_empty():return key.trim_prefix("counter:")
	if spec[5]=="copper":return "Mine copper"
	if spec[5]=="stone":return "Break fieldstone"
	return "Chop pine" if spec[2]=="pine" else "Chop alder"

func strike(id:String):
	var spec:Array=Life.NODES[id]
	impact_ore=spec[5]
	impact_at=spec[1]
	impact_stone=spec[5]!="wood"
	impact_left=.34
	if resource_sprites.has(id):
		var node:Sprite2D=resource_sprites[id]
		var tween:=node.create_tween()
		tween.tween_interval(.16)
		tween.tween_property(node,"rotation",.035,.055)
		tween.tween_property(node,"rotation",0,.16).set_trans(Tween.TRANS_SINE)


func update_mine(dt:float):
	if area!="Mine":return
	lamp_material.set_shader_parameter("player",pos)
	lamp_material.set_shader_parameter("lantern_on",Mine.lit(model))
	var drain:=.05 if Mine.lit(model) else .19
	if is_instance_valid(mine_beetle):
		var at:=Vector2(629+sin(elapsed*1.32)*53,410+sin(elapsed*1.96)*29)
		mine_beetle.position=at.round()
		mine_beetle.flip_h=cos(elapsed*1.32)<0
		mine_beetle.rotation=sin(elapsed*11)*.087
		targets["Shale beetle"]=at
		if pos.distance_to(at)<17:drain+=3.6
	model.s.mine.energy=maxf(0,float(model.s.mine.energy)-dt*drain)

func mine_strike(at:Vector2):
	impact_left=.34
	impact_stone=true
	impact_at=at



