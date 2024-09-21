local info = {
	event = 'setBgColor',
	name = 'Set BG color',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
color: Color name or index
]]
}


--onLoad, onOffset, onBeat

local function onBeat(event)
	cs.bgColor = tonumber(event.color) or event.color
	pq = pq.. "     set bgColor to " .. event.color
end


local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.setbgcolor,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	
	Event.property(event, 'colorIndex', 'color', 'Color index', {default = 0})
	
	
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties