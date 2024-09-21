local info = {
	event = 'calibration_finish',
	name = 'Calibration Finish',
	storeInChart = false,
	allowInNoVFX = true,
}


--onLoad, onOffset, onBeat
local function onBeat(event)
	cs.vfx.calibration:finish()
end



return info, onLoad, onOffset, onBeat