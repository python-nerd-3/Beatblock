local info = {
	event = 'bgNoise',
	name = 'BG noise (DEPRECIATED)',
	storeInChart = false,
	description = [[Parameters:
time: Beat to activate on
enable: Turn on/off noise. if false, all following arguments are optional
filename: Noise image to load
r:
g:
b:
a: RGBA values, from 0 to 1
]]
}


--onLoad, onOffset, onBeat
local function onLoad(event)
	if event.enable then
		cs.noiseCache = cs.noiseCache or {}
		cs.noiseCache[event.filename] = love.graphics.newImage("assets/game/noise/" .. event.filename)
		pq = pq.. '     loaded noise '  .. event.filename
	end
end

local function onBeat(event)
	cs.vfx.bgNoise_OLD.enable = event.enable
	if event.enable then
		cs.vfx.bgNoise_OLD.image = cs.noiseCache[event.filename]
		cs.vfx.bgNoise_OLD.r = event.r or cs.vfx.bgNoise_OLD.r
		cs.vfx.bgNoise_OLD.g = event.g or cs.vfx.bgNoise_OLD.g
		cs.vfx.bgNoise_OLD.b = event.b or cs.vfx.bgNoise_OLD.b
		cs.vfx.bgNoise_OLD.a = event.a or cs.vfx.bgNoise_OLD.a
		
		pq = pq .. "    ".. "BG Noise enabled with filename of " .. event.filename
	else
		pq = pq .. "    ".. "BG Noise disabled"
	end
end


local function editorProperties(event)
	Event.property(event,'bool', 'enable', 'Use BG noise?', {default = true})
	Event.property(event,'string', 'filename', 'Noise image to load', {default = ''})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties