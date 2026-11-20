extends Control

const Expansion=preload("res://scripts/expansion.gd")
const MAP_FONT=preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

var selected:="Farm"
var player_area:="Farm"
var player_pos:=Vector2.ZERO
var terrain:Texture2D
var trail_overlay:Texture2D
const LABELS={
	"Farm":[["Cottage",341,284],["Seedbeds",445,460],["Seed stall",676,330],["East to Willowbrook",1000,332]],
	"Village":[["Mercantile",355,247],["Iona’s stall",550,293],["Copper Kettle",732,253],["West to farm",108,336],["North to Grove",736,77],["River lodge",251,518],["Stave house",392,599],["Herbarium",621,551],["Arcade",982,308]],
	"Pasture":[["Livestock board",529,409],["Hay meadow",700,551],["Farm gate",564,694]],
	"Grove":[["Elderwood trail",101,606],["Alderwood Pond",405,392],["Alder grove",220,515],["Mine",960,467],["Copper ridge",991,515],["South to Willowbrook",729,709]],
}
const ART={"Farm":"farm-map","Village":"village-ground","Grove":"grove-ground"}

func set_region(id:String,current:String,at:Vector2):
	selected=id;player_area=current;player_pos=at
	terrain=load("res://assets/valley/"+ART[id]+".png") if ART.has(id) else load("res://assets/expansion/"+id.to_lower()+".png")
	trail_overlay=load("res://assets/trails/"+id.to_lower()+"-trail.png") if id in ["Grove","Village"] else null
	custom_minimum_size=Vector2(555,270)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw():
	if terrain==null:return
	var size_:Vector2=Vector2(size.x,255)
	draw_texture_rect(terrain,Rect2(Vector2.ZERO,size_),false,Color("#d8ddc9"))
	if trail_overlay!=null:draw_texture_rect(trail_overlay,Rect2(Vector2.ZERO,size_),false)
	var labels:Array=LABELS.get(selected,[])
	if Expansion.NAMES.has(selected):
		var spot:Array=Expansion.LANDMARKS[selected]
		var find:Array=Expansion.DISCOVERIES[selected]
		labels=[[spot[0],spot[2].x,spot[2].y],[find[2],find[1].x,find[1].y]]
		if selected=="Forest":labels.append(["Field lodge",723,496])
		if selected=="Marsh":labels.append(["Maelin’s apothecary",485,521])
	for item in labels:
		var pt:Vector2=Vector2(float(item[1])/1152,float(item[2])/768)*size_
		draw_texture_rect(preload("res://scripts/valley_details.gd").art(preload("res://scripts/valley_details.gd").emblem(item[0])),Rect2(pt-Vector2(8,4),Vector2(16,16)),false)
		var width:=MAP_FONT.get_string_size(item[0],HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+10
		var offset:=Vector2(-width*.5,-23 if item[0]!="Mint bank" else 8)
		draw_rect(Rect2(pt+offset,Vector2(width,19)),Color("#253f37"))
		draw_string(MAP_FONT,pt+offset+Vector2(5,15),item[0],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#fff1d2"))
	if player_area==selected:
		var pt:Vector2=player_pos/Vector2(1152,768)*size_
		draw_circle(pt,7,Color("#4a3c36"));draw_circle(pt,4,Color("#ffbd77"))

