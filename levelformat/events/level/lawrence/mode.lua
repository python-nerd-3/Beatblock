local info = {
	event = 'lawrence_mode',
	name = 'Lawrence Mode',
	storeInChart = false,
	description = [[Parameters:
time: Beat to set mode on
followPlayer: Whether the player is followed or not
]]
}


--onLoad, onOffset, onBeat
local function onLoad(event)
	--cs.LawrenceBG
	local startVal = 1
	local endVal = 0
	if event.followPlayer then
		startVal = 0
		endVal = 1
		rw:func(event.time, function() cs.vfx.LawrenceBG:resetPlayerRot() end)
	end
	Event.onLoad.ease({
		time = event.time,
		var = 'vfx.LawrenceBG.rotateMix',
		start = startVal,
		value = endVal,
		duration = 4,
		ease = 'outExpo'
	})
	
end


local function editorProperties(event)
	Event.property(event,'bool', 'followPlayer', 'Follow the player?', {default = false})
end



return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount