local info = {
	event = 'lawrence_init',
	name = 'Lawrence Init',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
]]
}


--onLoad, onOffset, onBeat
local function onLoad(event)
	cs.vfx.LawrenceBG = em.init('LawrenceBG',{x=project.res.cx,y=project.res.cy})
end



return info, onLoad, onOffset, onBeat