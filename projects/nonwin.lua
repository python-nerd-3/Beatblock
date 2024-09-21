local project = {}

project.release = true

project.name = 'Beatblock'

project.initState = 'Menu'
--cLevel = 'levels/Finished Levels/lawrence/'
--project.startBeat = 0
--project.frameAdvance = true

project.res = {}

project.res.useShuv = true

project.res.x = 600
project.res.y = 360
project.res.s = 2
project.fullscreen = false

project.intScale = 1

project.useImgui = false

project.doProfile = false

project.strictLoading = false --turn on to crash if level has unimplemented events


project.ctrls = {
	left = {"key:left", "axis:leftx-", "axis:rightx-", "button:dpleft"},
	right = {"key:right", "axis:leftx+", "axis:rightx+", "button:dpright"},
	up = {"key:up", "axis:lefty-", "axis:righty-", "button:dpup"},
	down = {"key:down", "axis:lefty+", "axis:righty+", "button:dpdown"},
	accept = {"key:space", "key:return", "button:a"},
	back = {"key:escape", "button:start"},
	
	tap1 = {"key:z", "key:space",  "mouse:1", "button:a"},
	tap2 = {"key:x", "key:lshift", "mouse:2", "button:x"},
	
	ctrl = {"key:lctrl", "key:rctrl"},
	alt = {"key:lalt", "key:ralt"},
	shift = {"key:lshift", "key:rshift"},
	delete = {"key:delete"},
	
	backspace = {"key:backspace"},
	plus = {"key:+", "key:="},
	minus = {"key:-"},
	leftbracket = {"key:["},
	rightbracket = {"key:]"},
	comma = {"key:,"},
	period = {"key:."},
	slash = {"key:/"},
	s = {"key:s"},
	x = {"key:x"},
	a = {"key:a"},
	c = {"key:c"},
	v = {"key:v"},
	g = {"key:g"},
	e = {"key:e"},
	p = {"key:p"},
	r = {"key:r"},
	i = {"key:i"},
	pause = {"key:tab"},
	k1 = {"key:1"},
	k2 = {"key:2"},
	k3 = {"key:3"},
	k4 = {"key:4"},
	k5 = {"key:5"},
	k6 = {"key:6"},
	k7 = {"key:7"},
	k8 = {"key:8"},
	f4 = {"key:f4"},
	f5 = {"key:f5"},
	mouse1 = {"mouse:1"},
	mouse2 = {"mouse:2"},
	mouse3 = {"mouse:3"},
  toggle_fullscreen = {"key:f11"}
}


project.acDelt = true

return project