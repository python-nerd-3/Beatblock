local info = {
	event = 'setBPM',
	name = 'Set BPM',
	storeInChart = false,
	allowInNoVFX = true,
	description = [[Parameters:
time: Beat to change BPM on
bpm: The BPM to change to
]]
}

--onLoad, onOffset, onBeat
local function onLoad(event)
	table.insert(cs.timingInfo.timingPoints,{beat = event.time, bpm = event.bpm})
	
end

local function onBeat(event) --...unsure if this works with scrubbing at all?
	cs.level.bpm = event.bpm
	
	if cs.rateMod then
		cs.level.bpm = cs.level.bpm * cs.rateMod
	end
	--cs.source:setBPM(event.bpm, event.time)
	pq = pq .. "    set bpm to "..event.bpm .. " !!"
	

end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.setbpm,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	
	Event.property(event,'decimal', 'bpm', 'BPM to change to', {step = 1, default = 100})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties