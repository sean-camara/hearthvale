extends RefCounted

# Time from the first lift to the last settling drop.
const DURATION:=.78
const IMPACT:=.36
var age:=DURATION
var destination:=Vector2.ZERO
var spout:=Vector2.ZERO
var side:=1.0

func start(from:Vector2,at:Vector2,facing:Vector2):
	age=0
	destination=at
	side=-1.0 if at.x<from.x-3 or (absf(at.x-from.x)<=3 and facing.x<0) else 1.0

func pose(tool_sprite:Sprite2D,at:Vector2):
	var lift:=smoothstep(0,.17,age)*(1.0-smoothstep(.55,DURATION,age))
	var tip:=smoothstep(.08,.23,age)*(1.0-smoothstep(.49,.74,age))
	var toward:=clampf((destination.y-at.y)*.15,-7,5)
	tool_sprite.position=Vector2(side*(9+8*lift),-13-8*lift+toward).round()
	tool_sprite.flip_h=side>0
	tool_sprite.rotation=side*(.08+.68*tip)
	var nozzle:=Vector2(side*10,-2 if tip<.25 else 0)
	spout=at+tool_sprite.position+nozzle.rotated(tool_sprite.rotation)

func draw_water(canvas:Node2D):
	for i in range(19):
		var emission:=.16+i*.019
		var flight_time:=.20+float(i%4)*.017
		var traveled:float=(age-emission)/flight_time
		var landing:=destination+Vector2(sin(i*2.39)*8,cos(i*2.39)*5)
		if traveled>=0.0 and traveled<1.0:
			var drop:=spout.lerp(landing,traveled)+Vector2(0,-12.0*sin(PI*traveled))
			var tail:=Vector2((landing.x-spout.x)*.055,2.0+traveled*2.8)
			canvas.draw_line(drop-tail,drop,Color("#76bedd"),1)
			canvas.draw_rect(Rect2(drop.round(),Vector2(2,2)),Color("#d8f9f3"))
		elif traveled>=1.0 and traveled<1.55:
			var pop:float=(traveled-1.0)/.55
			var rebound:=Vector2(sin(i*2.39)*5*pop,-sin(PI*pop)*5)
			canvas.draw_rect(Rect2((landing+rebound).round(),Vector2(1,2)),Color(.71,.91,1.0,1.0-pop))
	for i in range(2):
		var ripple:=clampf((age-IMPACT-i*.13)/.22,0,1)
		if ripple>0 and ripple<1:
			var ring:=PackedVector2Array()
			for p in range(17):
				var point:=Vector2.from_angle(p*TAU/16)*Vector2(10,4)*ripple
				ring.append(destination+point)
			canvas.draw_polyline(ring,Color(.53,.86,.95,(1-ripple)*.72),1)

