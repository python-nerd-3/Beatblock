local info = {
	event = 'tutorial_init',
	name = 'Tutorial Init',
	storeInChart = false,
	allowInNoVFX = true,
}


--onLoad, onOffset, onBeat
local function onLoad(event)
	cs.vfx.tutorial = em.init('Tutorial',{})
end



return info, onLoad, onOffset, onBeat