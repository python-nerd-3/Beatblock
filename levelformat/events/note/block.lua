local info = {
	event = 'block',
	name = 'Block',
	storeInChart = true,
	allowInNoVFX = true,
	--hits = 1,
	description = [[Parameters:
time: Beat to spawn on
angle: Angle to spawn at
endAngle: (Optional) Angle to end up at
spinEase: (Optional) Ease to use while rotating
speedMult: (Optional) Speed multiplier for approach
]]
}



local function hitCount(event)
	if event.tap then
		return 2
	else
		return 1
	end
end

--onLoad, onOffset, onBeat
local function onOffset(event)
	
	local newNote = em.init("Block",{
		x=project.res.cx,
		y=project.res.cy,
		angle = event.angle,
		endAngle = event.endAngle,
		spinEase = event.spinEase,
		hb = event.time,
		sMult = event.speedMult,
		tap = event.tap
	})
	pq = pq .. "    ".. "spawn here!"
	newNote:update(dt)
	
end

local function editorDraw(event)	
	if event.isCursor then
    local pos = cs:getPosition(event.angle, event.time)
		love.graphics.draw(sprites.note.square,pos[1],pos[2],0,1,1,8,8)
		return
	end
	local note = Block:new({
		x=project.res.cx,
		y=project.res.cy,
		angle = event.angle,
		hb = event.time,
		tap = event.tap
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
	Event.property(event,'bool', 'tap', 'Make this note a Tap note', {optional = true, default = true})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount