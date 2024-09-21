local info = {
	event = 'calibration_init',
	name = 'Calibration Init',
	storeInChart = false,
	allowInNoVFX = true,
}


--onLoad, onOffset, onBeat
local function onLoad(event)
	cs.vfx.calibration = em.init('Calibration',{})
end



return info, onLoad, onOffset, onBeat