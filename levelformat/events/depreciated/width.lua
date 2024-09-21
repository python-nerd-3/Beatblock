local info = {
	event = 'width',
	name = '[DEPRECATED] Set Width',
	storeInChart = false,
	description = [[Parameters:
time: Beat to start width change
newWidth: New width to ease to
duration: Length of ease (in 1/60th of seconds, will get changed to beats at some point)
ease: (Optional) Ease function to use
]]
}

--onLoad, onOffset, onBeat
--[[
local function onBeat(event)
	local e = event.ease or 'linear'
	flux.to(cs.p,event.duration,{paddleSize=event.newWidth}):ease(e)
	pq = pq.. "    width set to " .. event.newWidth
end
]]
local function onLoad(event)
	local duration = event.duration or 0
	local ease = event.ease or 'linear'
	rw:ease(event.time,duration,ease,event.newWidth,cs.p.paddles[1],'paddleSize',nil,event.order)
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.width,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'int', 'newWidth', 'New width to ease to', {default = 70})
	Event.property(event,'decimal', 'duration', 'Length of ease (in beats)', {step = cs:getBeatStep(), default = 0})
	Event.property(event,'enum', 'ease', 'Ease function to use', {enum = 'ease', optional = true, default = 'linear'})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties