local info = {
	event = 'noise',
	name = 'Noise',
	storeInChart = false,
	description = [[Parameters:
time: Beat to activate on
chance: Chance per pixel, from 0 to 1. 0 completely disables.
color: Color index
]]
}


--onLoad, onOffset, onBeat
local function onLoad(event)

end

local function onBeat(event)
	cs.vfx.bgNoise = event.chance
	cs.vfx.bgNoiseColor = event.color
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.noise,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	
	Event.property(event,'decimal', 'chance', 'Chance per pixel, from 0 to 1, to be clear. 0 completely disables.', {step = 0.01, default = 0})
	Event.property(event, 'colorIndex', 'color', 'Color index', {default = 0})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties