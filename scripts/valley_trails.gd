extends RefCounted

static var trails:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trails.json"))

static func distance_to_trail(area:String,at:Vector2)->float:
	var distance:=INF
	for path:Array in trails.get(area,[]):
		for index in range(1,path.size()):
			var from:=Vector2(path[index-1][0],path[index-1][1])
			var to:=Vector2(path[index][0],path[index][1])
			distance=minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,from,to)))
	return distance

