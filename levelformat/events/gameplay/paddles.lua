local info = {
	event = 'paddles',
	name = 'Edit Paddles',
	storeInChart = false,
	allowInNoVFX = true,
	description = [[Parameters:
paddle: Paddle to Change
time: Beat to start the change
enabled: Whether the paddle is enabled
newWidth (Optional): New width to ease to
newAngle (Optional): New angle to ease to
duration: Length of ease (in 1/60th of seconds, will get changed to beats at some point)
ease: (Optional) Ease function to use
]]
}

local function onLoad(event)
	local duration = event.duration or 0
	local ease = event.ease or 'linear'
	local paddleStart = event.paddle
	local paddleEnd = event.paddle 
	if event.paddle == 0 then
		paddleStart = 1
		paddleEnd = #cs.p.paddles
	end
	for i=paddleStart,paddleEnd do
    rw:ease(event.time,duration,ease,event.newAngle,cs.p.paddles[i],'baseAngle',nil,event.order)
		rw:ease(event.time,duration,ease,event.newWidth,cs.p.paddles[i],'paddleSize',nil,event.order)
	end
    
end
local function onBeat(event)
	local paddleStart = event.paddle
	local paddleEnd = event.paddle 
	if event.paddle == 0 then
		paddleStart = 1
		paddleEnd = #cs.p.paddles
	end
	for i=paddleStart,paddleEnd do
		if event.enabled ~= nil then
			cs.p.paddles[i].enabled = event.enabled
		end
	end
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	love.graphics.draw(sprites.editor.events.paddle,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
  Event.property(event, 'bool', 'enabled', 'Change this paddle\'s enabled status?', {optional = true, default = false})
  Event.property(event,'int', 'paddle', 'What paddle to change? 0 = all paddles', {default = 1, min=0, max=8})
	Event.property(event,'int', 'newWidth', 'New width to ease to', {default = 70, optional=true})
  Event.property(event,'int', 'newAngle', 'New angle to ease to', {default = 0, optional=true})
	Event.property(event,'decimal', 'duration', 'Length of ease (in beats)', {step = cs:getBeatStep(), default = 0})
	Event.property(event,'enum', 'ease', 'Ease function to use', {enum = 'ease', default = 'linear'})
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties