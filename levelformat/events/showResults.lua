local info = {
	event = 'showResults',
	name = 'Show Results',
	storeInChart = false,
	allowInNoVFX = true,
	description = [[Parameters:
time: Beat to show results on
]]
}

--onLoad, onOffset, onBeat
local function onBeat(event)
	cs.p:growTransition(function() cs:goToResults() end)
end


local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.showresults,pos[1],pos[2],0,1,1,8,8)
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties