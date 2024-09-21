local info = {
	event = 'mine',
	name = 'Mine',
	storeInChart = true,
	allowInNoVFX = true,
	hits = 1,
	description = [[Parameters:
time: Beat to spawn on
angle: Angle to spawn at
endAngle: (Optional) Angle to end up at
spinEase: (Optional) Ease to use while rotating
speedMult: (Optional) Speed multiplier for approach
]]
}

local function hitCount(event)
	return 1
end

--onLoad, onOffset, onBeat
local function onOffset(event)
	
	local newNote = em.init("Mine",{
		x=project.res.cx,
		y=project.res.cy,
		angle = event.angle,
		endAngle = event.endAngle,
		spinEase = event.spinEase,
		hb = event.time,
		sMult = event.speedMult
	})
	pq = pq .. "    ".. "mine here!"
	newNote:update(dt)
	
end


local function editorDraw(event)
	if event.isCursor then
    local pos = cs:getPosition(event.angle, event.time)
		love.graphics.draw(sprites.note.mine,pos[1],pos[2],0,1,1,8,8)
		return
	end
	local note = Mine:new({
		x=project.res.cx,
		y=project.res.cy,
		angle = event.angle,
		hb = event.time,
	})
	note:updateProgress()
  note:updateAngle()
  
	note:updatePositions()
	note:draw()
	
end

local function editorProperties(event)
	Event.property(event,'decimal', 'endAngle', 'Angle to end up at', {step = cs:getAngleStep(), optional = true, default = 0})
	Event.property(event,'enum', 'spinEase', 'Ease to use while rotating', {enum = 'ease', optional = true, default = 'linear'})
	Event.property(event,'decimal', 'speedMult', 'Speed multiplier for approach', {step = 0.01, optional = true, default = 1})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount