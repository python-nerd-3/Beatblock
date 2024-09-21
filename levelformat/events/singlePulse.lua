local info = {
	event = 'singlePulse',
	name = 'Pulse',
	storeInChart = false,
	description = [[Parameters:
time: Beat to pulse on
intensity: (Optional) How far out to pulse, defaults to 10.
]]
}

--onLoad, onOffset, onBeat
local function onBeat(event)
	pq = pq.. "    pulsing"
	cs.p.extend = event.intensity or 10
	flux.to(cs.p,10,{extend=0}):ease("linear")
end


return info, onLoad, onOffset, onBeat