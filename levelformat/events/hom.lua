local info = {
	event = 'hom',
	name = 'Hall of Mirrors',
	storeInChart = false,
	description = [[Parameters:
time: Beat to toggle HOM on
enable: Turns on/off HOM
]]
}

--onLoad, onOffset, onBeat
local function onBeat(event)
	cs.vfx.hom = event.enable

	if event.enable then
		pq = pq .. "    ".. "Hall Of Mirrors enabled"
		error("when the bob is cranky!")
	else
		pq = pq .. "    ".. "Hall Of Mirrors disabled"
	end
end


local function editorProperties(event)
	Event.property(event,'bool', 'enable', 'Use HOM?', {default = true})
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.mirrorzone,pos[1],pos[2],0,1,1,8,8)
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties