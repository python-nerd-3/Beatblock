local info = {
	event = 'setBG',
	name = 'Set BG',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
file: BG image to load
]]
}


--onLoad, onOffset, onBeat
local function onLoad(event)
	cs.bgCache = cs.bgCache or {}
	cs.bgCache[event.file] = love.graphics.newImage("assets/bgs/".. event.file)
	pq = pq.. '     loaded bg '  .. event.file
end

local function onBeat(event)
	cs.bg = cs.bgCache[event.file]
	pq = pq.. "     set bg to " .. event.file
end


return info, onLoad, onOffset, onBeat