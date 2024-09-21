local info = {
	event = 'multiPulse',
	name = 'Multipulse',
	storeInChart = false,
	description = [[Parameters:
time: Beat to start pulsing
reps: How many extra pulses
delay: Time between pulses
intensity: (Optional) How far out to pulse, defaults to 10.
]]
}

--onLoad, onOffset, onBeat
local function onBeat(event)
	pq = pq.. "    pulsing, generating other pulses"
	cs.p.extend = event.intensity or 10
	flux.to(cs.p,10,{extend=0}):ease("linear")
	for i=1,event.reps do
		table.insert(cs.playEvents,{type="singlePulse",time=event.time+event.delay*i,intensity=event.intensity})
	end
end


return info, onLoad, onOffset, onBeat