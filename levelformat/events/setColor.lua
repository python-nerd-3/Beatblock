local info = {
	event = 'setColor',
	name = 'Set color',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
color: color index
r (Optional): red value 
g (Optional): green value
b (Optional): blue value
duration (Optional): length of ease
ease (Optional): ease to use
]]
}


--onLoad, onOffset, onBeat

local function onLoad(event)
	local duration = event.duration or 0
	local ease = event.ease or 'linear'
	rw:ease(event.time,duration,ease,{r = event.r, g = event.g, b = event.b},shuv.pal[event.color],nil,nil,event.order)
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.setcolor,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	
	--Event.property(event,'bool', 'enable', 'Use HOM?', {default = true})
	
	Event.property(event, 'colorIndex', 'color', 'Color index', {default = 0})
	
	local r,g,b = event.r or 0, event.g or 0, event.b or 0
	local renable,genable,benable = event.r ~= nil, event.g ~= nil, event.b ~= nil 
	
	--r,g,b = imgui.ColorEdit3("##colorbox", r/255,g/255,b/255);
	r,g,b = helpers.imguiColor('##colorbox',r,g,b)
	
	renable = imgui.Checkbox('Enable red channel',renable)
	genable = imgui.Checkbox('Enable green channel',genable)
	benable = imgui.Checkbox('Enable blue channel',benable)
	
	if renable then
		event.r = r
	else
		event.r = nil
	end
	if genable then
		event.g = g
	else
		event.g = nil
	end
	if benable then
		event.b = b 
	else
		event.b = nil
	end
	
	
	Event.property(event,'decimal', 'duration', 'Length of ease', {step = cs:getBeatStep(), optional = true, default = 0})
	Event.property(event,'enum', 'ease', 'Ease function to use', {enum = 'ease', optional = true, default = 'linear'})
	
	
	
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties