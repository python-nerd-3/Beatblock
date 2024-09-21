local info = {
	event = 'paddleCount',
	name = '[DEPRECATED] Set Paddle Count',
	storeInChart = false,
	description = [[Parameters:
time: Beat to change Paddle Count
paddles: New number of Paddles
]]
}

--onLoad, onOffset, onBeat
local function onBeat(event)
	local e = event.ease or 'linear'
	cs.p.paddleCount = event.paddles
	pq = pq.. "    paddle count set to " .. event.paddles
end


local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)

	love.graphics.draw(sprites.editor.events.paddlecount,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'int', 'paddles', 'New number of Paddles', {default = 1})
	
	if event.paddles > 8 then
		event.paddles = 8
	end
	
	if event.paddles < 0 then
		event.paddles = 0
	end
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties