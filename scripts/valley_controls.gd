extends RefCounted

const DEFAULTS:={"Up":KEY_W,"Left":KEY_A,"Down":KEY_S,"Right":KEY_D,"Run":KEY_SHIFT,"Interact":KEY_E,"Work / reel":KEY_SPACE,"Satchel":KEY_I,"Journal":KEY_J,"Map":KEY_M,"Workshop":KEY_C}

static func code(model,action:String)->int:
	return int(model.s.expansion.projects.get("bind-"+action,DEFAULTS[action]))

static func name_for(model,action:String)->String:
	return OS.get_keycode_string(code(model,action))

static func equivalent(model,key:int)->int:
	for action:String in DEFAULTS:
		if code(model,action)==key:return DEFAULTS[action]
	if key in DEFAULTS.values():return 0
	return key

static func held(model,action:String)->bool:
	return Input.is_physical_key_pressed(code(model,action))

static func assign(model,action:String,key:int)->bool:
	if key in [KEY_ESCAPE,KEY_ENTER,KEY_TAB,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN] or (key>=KEY_0 and key<=KEY_9):return false
	for other:String in DEFAULTS:
		if other!=action and code(model,other)==key:return false
	model.s.expansion.projects["bind-"+action]=key
	return true

