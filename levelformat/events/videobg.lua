local info = {
	event = 'videoBG',
	name = 'Play Videobg',
	storeInChart = false,
	description = [[Parameters:
time: Beat to start playing video
file: Filename of video, MUST BE OGV
]]
}

--onLoad, onOffset, onBeat
local function onLoad(event)
	cs.videoBG = love.graphics.newVideo(cLevel..event.file)
	pq = pq .. "      loaded videoBG"
end

local function onBeat(event)
	pq = pq .. "    ".. "playing videoBG"
	cs.drawVideoBG = true
	cs.videoBG:play()
	
end


return info, onLoad, onOffset, onBeat