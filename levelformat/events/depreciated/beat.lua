local info = {
	event = 'beat',
	name = 'Spawn Block (LEGACY)',
	storeInChart = true,
	hits = 1,
	description = [[Parameters:
time: Beat to spawn on
angle: Angle to spawn at
endAngle: (Optional) Angle to end up at
spinEase: (Optional) Ease to use while rotating
speedMult: (Optional) Speed multiplier for approach
]]
}

--onLoad, onOffset, onBeat
local function onOffset(event)
	Event.onOffset['block'](event)
	
end


return info, onLoad, onOffset, onBeat