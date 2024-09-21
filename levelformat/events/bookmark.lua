local info = {
	event = 'bookmark',
	name = 'Bookmark',
	storeInChart = false,
	description = [[Parameters:
time: Beat to start
name: Name of the section after the bookmark - if blank, the bookmark won't appear when traversing the level
r: Red component of color to draw the ring the bookmark is on - if blank, won't draw this ring
g: Green component of color to draw the ring the bookmark is on - if blank, won't draw this ring
b: Blue component of color to draw the ring the bookmark is on - if blank, won't draw this ring
description: Information about the section after the bookmark
]]
}

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.bookmark,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'name', 'Name of the section after the bookmark', {default = 'Section'})
	
	local r,g,b = event.r or 0, event.g or 0, event.b or 0
	
	r,g,b = imgui.ColorEdit3("##colorbox", r/255,g/255,b/255);
	
	event.r = r * 255
	event.g = g * 255
	event.b = b * 255
	
	Event.property(event,'string', 'description', 'Information about the section after the bookmark', {default = ''})
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties