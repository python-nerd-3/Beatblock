local info = {
	event = 'extraTap',
	name = 'Extra Tap',
	storeInChart = true,
	allowInNoVFX = true,
	--hits = 1,
	description = [[Parameters:
]]
}

local function hitCount(event)
	return 1
end
--onLoad, onOffset, onBeat
local function onOffset(event)
	
	local newNote = em.init("ExtraTap",{
		x=project.res.cx,
		y=project.res.cy,
		angle = 0,
		hb = event.time,
		sMult = event.speedMult,
	})
	pq = pq .. "    ".. "spawn here!"
	newNote:update(dt)
	
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.extratap,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'decimal', 'speedMult', 'Speed multiplier for approach', {step = 0.1, optional = true, default = 1.5})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount