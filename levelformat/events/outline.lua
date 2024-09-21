local info = {
	event = 'outline',
	name = 'Outline',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
enable (Optional): Show outline
color: Color index
]]
}


local function onBeat(event)
	if event.enable == false then
		cs.outline = nil
		pq = pq.. "     disabled outline "
	else
		cs.outline = event.color
		pq = pq.. "     set outline to "..cs.outline
	end
end


local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.outline,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	
	Event.property(event,'bool', 'enable', 'Show an outline?', {default = true})
	Event.property(event, 'colorIndex', 'color', 'Color index', {default = 0})
	
	
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties