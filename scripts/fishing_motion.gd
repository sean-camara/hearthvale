extends RefCounted

const RECOVERY:=.92
var species:="minnow"
var phase:=""
var age:=0.0
var water:=Vector2.ZERO
var facing:=Vector2.UP

func start(world,point:Vector2):
	water=point
	if world.normal_farmer!=null:world.runner.texture=world.normal_farmer
	facing=(water-world.pos).normalized()
	if facing.is_zero_approx():facing=Vector2.UP
	world.direction=facing
	world.sitting=false
	world.working=0
	world.tool_sprite.hide()
	phase="cast"
	age=0

func update(world,dt:float,hooked:bool):
	if phase=="":return
	age+=dt
	if phase in ["cast","wait","bite"]:
		phase="bite" if hooked else ("cast" if age<.52 else "wait")
	elif age>=RECOVERY:
		clear(world)
		return
	var sprite:Sprite2D=world.runner
	var rod:Sprite2D=world.tool_sprite
	var side:=signf(facing.x) if absf(facing.x)>.15 else 1.0
	var row:int=world.direction_row(facing)
	var windup:=sin(PI*clampf(age/.52,0,1))
	var haul:=sin(PI*clampf(age/.8,0,1)) if phase in ["catch","miss"] else 0.0
	var tug:=.11*sin(age*16) if phase=="bite" else 0.0
	sprite.frame=row*4+(2 if windup>.35 or haul>.25 else 0)
	sprite.position=(world.pos-facing*haul*4+Vector2(0,-windup*2)).round()
	sprite.rotation=side*(-.07*windup+.09*haul)
	rod.visible=true
	rod.texture=world.tex.get("cast-rod",world.tex["item-rod"])
	rod.z_index=0 if row==3 else 1
	rod.scale=Vector2.ONE*.92
	rod.flip_h=side<0
	rod.position=(facing*10+Vector2(side*5,-16)).round()
	rod.rotation=side*(-.20-1.2*windup-.98*haul+tug)
	world.marks.queue_redraw()

func resolve(caught:bool):
	phase="catch" if caught else "miss"
	age=0

func clear(world):
	if phase=="":return
	phase=""
	world.runner.rotation=0
	world.tool_sprite.hide()
	world.tool_sprite.scale=Vector2.ONE*.48
	world.marks.queue_redraw()

func fishing_point(world)->Vector2:
	var hand:Vector2=world.runner.position+world.tool_sprite.position
	var pole:Vector2=(Vector2(16,-11)*Vector2(-1 if world.tool_sprite.flip_h else 1,1)).rotated(world.tool_sprite.rotation)
	return hand+pole

func draw(world):
	if phase=="":return
	var canvas:Node2D=world.marks
	var tip:=fishing_point(world)
	var landing:=water
	var ripple_time:=age
	if phase=="cast":
		var flight:=smoothstep(.16,.50,age)
		landing=tip.lerp(water,flight)+Vector2(0,-sin(PI*flight)*18)
	elif phase=="catch" or phase=="miss":
		var lift:=smoothstep(.08,.61,age)
		landing=water.lerp(world.pos+Vector2(0,-34),lift)+Vector2(0,-sin(PI*lift)*26)
	elif phase=="bite":
		if species in ["pike","trout","coast-bass"]:landing+=Vector2(sin(age*6)*11,absf(sin(age*6))*4)
		elif species in ["minnow","smelt","reedling"]:landing+=Vector2(0,pow(maxf(0,sin(age*19)),2)*5)
		else:landing+=Vector2(sin(age*12)*3,absf(sin(age*13))*4)
	else:
		ripple_time=age-.52
		landing+=Vector2(0,sin(age*5)*1.5)
	canvas.draw_polyline(PackedVector2Array([tip,tip.lerp(landing,.52)+Vector2(0,3),landing]),Color("#f5e9c5"),1)
	if world.tex.has("cast-bobber"):
		canvas.draw_texture_rect(world.tex["cast-bobber"],Rect2(landing-Vector2(4,6),Vector2(8,9)),false)
	else:canvas.draw_rect(Rect2(landing-Vector2(2,4),Vector2(4,5)),Color("#eea140"))
	if phase in ["wait","bite","catch","miss"]:
		var pulse:=fposmod(ripple_time*1.4,1)
		canvas.draw_arc(water,3+pulse*13,0,TAU,18,Color(.81,.94,.93,(1-pulse)*.72),1)
		if age<.25 or phase=="bite":
			if world.tex.has("cast-splash"):
				canvas.draw_texture_rect(world.tex["cast-splash"],Rect2(water-Vector2(13,12),Vector2(26,18)),false,Color(1,1,1,1-pulse*.66))
	if phase=="catch" and age>.08:
		var catch_art:Texture2D=world.tex.get("catch-"+species,world.tex["cast-fish"])
		canvas.draw_set_transform(landing, sin(age*17)*.27)
		canvas.draw_texture_rect(catch_art,Rect2(-13,-8,26,16),false)
		canvas.draw_set_transform(Vector2.ZERO)

