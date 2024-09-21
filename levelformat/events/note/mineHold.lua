local info = {
	event = 'mineHold',
	name = 'MineHold',
	storeInChart = true,
	allowInNoVFX = true,
	hits = 1,
	description = [[Parameters:
time: Beat to spawn on
angle1: First Angle to spawn at
angle2: Second Angle to spawn at
duration: How many beats the MineHold will last
segments: (Optional) Force a certain number of line segments
holdEase: (Optional) Change ease from angle1 to angle2
endAngle: (Optional) First Angle to end up at
spinEase: (Optional) Ease to use while rotating
speedMult: (Optional) Speed multiplier for approach
]]
}

local function hitCount(event)
	return 1
end

--onLoad, onOffset, onBeat
local function onOffset(event)
	
	local newNote = em.init("MineHold",{
		x = project.res.cx,
		y = project.res.cy,
		segments = event.segments,
		duration = event.duration,
		holdEase = event.holdEase,
		angle = event.angle,
		angle2 = event.angle2,
		endAngle = event.endAngle,
		spinEase = event.spinEase,
		hb = event.time,
		sMult = event.speedMult,
		tickRate = event.tickRate
	})
	pq = pq .. "    ".. "minehold spawn here!"
	newNote:update(dt)
	
end

local function isBetween(x, low, high)
  return x >= low and x <= high
end

local function shouldEditorDraw(event, beat, endBeat)
  -- min and max are special handling for negative holds
  local holdStart = math.min(event.time, event.time + event.duration)
  local holdEnd = math.max(event.time, event.time + event.duration)
  
  return isBetween(beat, holdStart, holdEnd) or isBetween(endBeat, holdStart, holdEnd) or isBetween(holdStart, beat, endBeat)
end

local function editorDraw(event, beat, endBeat)
	
	if event.isCursor then
    local pos = cs:getPosition(event.angle, event.time)
		love.graphics.draw(sprites.note.minehold,pos[1],pos[2],0,1,1,8,8)
		return
	end
	
	local hold = MineHold:new({
		x = project.res.cx,
		y = project.res.cy,
		segments = event.segments,
		duration = event.duration,
		holdEase = event.holdEase,
		angle = event.angle,
		angle2 = event.angle2,
		spinEase = event.spinEase,
		hb = event.time,
	})

	hold:updateProgress()
	hold:updateAngle()
	hold:updatePositions()
	if hold:checkIfActive() then
		hold:updateDuringHit()
	end
	
	hold:draw()

end

local function editorProperties(event)
	
	Event.property(event,'decimal', 'angle2', 'Angle for end of the hold', {step = cs:getAngleStep(), default = event.angle})
	Event.property(event,'decimal', 'duration', 'How many beats the hold lasts', {step = cs:getBeatStep(), default = 1,min = 0})

	
	
	Event.property(event,'int', 'segments', 'Force a certain number of line segments', {optional = true, default = 1, min = 1})
	Event.property(event,'enum', 'holdEase', 'Change ease from angle1 to angle2', {enum = 'ease', optional = true, default = 'linear'})
	Event.property(event,'decimal', 'endAngle', 'Angle to end up at', {step = cs:getAngleStep(), optional = true, default = 0})
	Event.property(event,'enum', 'spinEase', 'Ease to use while rotating', {enum = 'ease', optional = true, default = 'linear'})
	Event.property(event,'decimal', 'speedMult', 'Speed multiplier for approach', {step = 0.01, optional = true, default = 1})
	Event.property(event,'decimal', 'tickRate', 'If this mineHold has been hit, how frequently should it check for hits again?', {step = cs:getBeatStep(), optional = true, default = 0.5})
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount, shouldEditorDraw