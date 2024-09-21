local info = {
	event = 'lawrence_changeOffset',
	name = 'Lawrence Change Offset',
	storeInChart = false,
	description = [[Parameters:
time: Beat to set mode on
followPlayer: Whether the player is followed or not
]]
}


--onLoad, onOffset, onBeat
local function onBeat(event)
	
	cs.vfx.LawrenceBG:changeOffset(event.offsetDelta,event.time)
	
end

local function editorProperties(event)
	Event.property(event,'int', 'offsetDelta', 'How much to change offset by', {default = 1})
end



return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount
