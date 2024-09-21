Hold = class ('Hold', Block)

function Hold:initialize(params)
	
	self.angle2 = 0 
	self.drawAngle2 = 0 
	self.holdEase = nil
	self.sMult2 = 1
	self.mineStripe = false
	self.endTap = false
	
	self.leniencyFrames = 15
	self.timeOff = 0
	
	Block.initialize(self,params)
	self.name = 'hold'
	self.x2 = self.x
	self.y2 = self.y
	
	self.reachedEnd = false
	
	self.spr = animations.note.hold
	
	if self.endTap then
		self.endTapManager = cs.gm:newTap(self.hb + self.duration,true,self.tapTimingWindow)
	end
	
end

function Hold:checkEndTap()
	if not self.endTap then
		return true
	end
	return self.endTapManager.hit
end

function Hold:checkEndPassedWindow()
	if not self.endTap then
		return false
	end
	return self.endTapManager:passedWindow()
end

function Hold:getPositions()
	local distance2 = (self.hb - cs.cBeat+self.duration)
	
	self.drawAngle2 = cs.gm:getVFXAngle(self.angle2,distance2)
	local speed = cs.level.properties.speed*cs.scrollSpeed*self.sMult*self.sMult2
	if cs.editMode then
		speed = cs.zoom
	end
	local finalDistance2 = distance2*speed+cs.p:getDistance()
	if cs.editMode then
		finalDistance2 = finalDistance2 - cs.noteRadius + 1
	end
	return Block.getPositions(self), helpers.rotate(finalDistance2,self.drawAngle2,self.ox,self.oy)
end

function Hold:updateDuringHit()
	local progress = math.min(((self.hb - cs.cBeat)*-1)/self.duration,1)
	self.angle = helpers.interpolate(self.endAngle,self.angle2,progress, self.holdEase)
	self.drawAngle = self.angle
	local playerDistance = cs.p:getDistance()
	if cs.editMode then
		playerDistance = playerDistance - cs.noteRadius + 1
	end
	local p1 = helpers.rotate(playerDistance,self.angle,self.ox,self.oy)
	self.x = p1[1]
	self.y = p1[2]  
end

function Hold:update(dt)
  prof.push('hold update')
	
	self:updateProgress()
	self:updateAngle()
	
	
	self:updatePositions()
	
	
	if self:checkIfActive() then
		local progress = math.min(((self.hb - cs.cBeat)*-1)/self.duration,1)
		
		self:updateDuringHit()
		
		local hit, barely = self:checkTouchingPaddle(self.angle) 
		
		if (not self.hitYet) and cs.gm.noBarelyJudgements and barely then 
			hit = false
			barely = false
		end
		
		if hit then
			self.timeOff = 0
		end
		
		if self.hitYet and (not hit) and (not (progress >= 1)) then
			self.timeOff = self.timeOff + dt
			if self.timeOff < (self.leniencyFrames + math.max(cs.extraHoldLeniency,0)) then
				hit = true
			end
		end
		if hit then 
			if self.hitYet == false then
				self.hitYet = true
				pq = pq .. "   started hitting hold"
				if self.tap and savedata.options.audio.hitsounds then
					te.playOne(sounds.tap,"static",'sfx',0.5)
				end
				if barely then
					
					if savedata.options.audio.hitsounds then
						te.playOne(sounds.hold,"static",'sfx',0.75)
					end
					te.playOne(sounds.barely,"static",'sfx',1.5)
				else
					
					if savedata.options.audio.hitsounds then
						te.playOne(sounds.hold,"static",'sfx')
					end
				end
				self:makeParticles(true)
				cs.gm:addToScore(1,barely)
				cs.p:doPaddleFeedback()
			end
			
			if progress >= 1 then
				if not self.reachedEnd then
					self.reachedEnd = true
					if self.endTap and savedata.options.audio.hitsounds then
						te.playOne(sounds.tap,"static",'sfx',0.5)
					end
					self:onHit()
					cs.gm:addToScore()
				end
				if self:checkEndTap() then
					self:cleanup()
				end
			end
			
		else
			self:onMiss()
			cs.gm:handleMiss()
			if not self.hitYet then --add another miss if the start was not hit
				cs.gm:handleMiss()
			end
			self:cleanup()
		end
	end
	
	
	if self:checkTap() and self.tap then --hit first tap?
		self.tap = false
		self.tapManager.delete = true
	end
	if self:checkEndTap() and self.endTap then  -- hit second tap?
		self.endTap = false
		self.endTapManager.delete = true
	end
	
		
	if self:checkPassedWindow() then -- missed first tap?
		self:onMiss(true)
		self.tap = false
		self.tapManager.delete = true
	end
	
	if self:checkEndPassedWindow() then -- missed second tap?
		self:onMiss(true)
		self.endTap = false
		self.endTapManager.delete = true
	end
	
  prof.pop('hold update')
end

function Hold:cleanup()
	if self.tapManager then
		self.tapManager.delete = true
	end
	
	if self.endTapManager then
		self.endTapManager.delete = true
	end
	self.delete = true
end

function Hold.drawHold(ox, oy, x, y, x2, y2, completion, endAngle, angle2, segments, sprite, holdEase, hType)
	local newhold = {
		ox = ox, 
		oy = oy,
		x = x,
		y = y,
		x2 = x2,
		y2 = y2,
		angle2 = angle2 ,
		segments = segments,
		holdEase = holdEase
	}
	if hType == 'hold' then
		newhold.mineStripe = false
		newhold.spr = sprites.note.hold
	else
		newhold.mineStripe = true
		newhold.spr = sprites.note.minehold
	end
	
	Hold.draw(newhold, completion)
end

function Hold:draw(completion)
  prof.push('hold draw')
	completion = completion or  helpers.clamp(((cs.cBeat - self.hb) / self.duration),0,1)

  -- distances to the beginning and the end of the hold
  local len1 = helpers.distance({self.ox, self.oy}, {self.x, self.y})
  local len2 = helpers.distance({self.ox, self.oy}, {self.x2, self.y2})
  local points = {}

  -- how many segments to draw
  -- based on the beat's angles by default, but can be overridden in the json
	local segments = self.segments
	

	if segments == nil then
		segments = math.floor(math.abs(self.drawAngle2 - self.drawAngle) + 12)
	end
	if math.floor(cs.vfx.holdSegmentLimit) >= 1 then
		segments = math.min(math.floor(cs.vfx.holdSegmentLimit),segments)
	end
	
	local firstPoint = (helpers.interpolate(self.endAngle, self.drawAngle2, completion, self.holdEase) - self.drawAngle2)
	local multiplier = 1
	if firstPoint ~= 0 then
		multiplier = (self.angle - self.drawAngle2) / firstPoint
	end

  for i = 0, segments do
    local t = i / segments
    local angle_t = t * (1 - completion) + completion
    -- coordinates of the next point
		local firstPoint = self.drawAngle
		if completion ~= 0 then
			firstPoint =  self.endAngle
		end
    local nextAngle = helpers.interpolate(firstPoint, self.drawAngle2, angle_t, self.holdEase)
		
		local distanceFromEnd = nextAngle - self.drawAngle2
		
		
		if completion ~= 0 then
			nextAngle = self.drawAngle2 + distanceFromEnd  *multiplier
		end
		
		nextAngle = math.rad(nextAngle - 90)
		
    local nextDistance = helpers.lerp(len1, len2, t)
    points[#points+1] = math.cos(nextAngle) * nextDistance + self.ox
    points[#points+1] = math.sin(nextAngle) * nextDistance + self.oy
  end
	
	if self.mineStripe and completion > 0 and (completion < 1 or (math.abs(math.rad(self.angle2 - self.lastParticleAngle)) > 2*self.radsPerParticle)) and (not cs.editMode) then
		self:updateParticles(points[3], points[4], completion)
		if (not self.startParticleCreated) then
			if self.duration == 0 then
				em.init("MineExplosion", {x = self.lastX, y = self.lastY})
			else
				em.init("MineExplosion", {x = self.x, y = self.y})
			end
			self.startParticleCreated = true
		end
	end
	
	if self.mineStripe then --for 0-dur mineholds
		self.lastX = self.x
		self.lastY = self.y
	end
	
	outline(function()
		-- need at least 2 points to draw a line ,
		if #points >= 4 and completion < 1 then
			-- draw the black outline
			color('black')
			love.graphics.setLineWidth(cs.noteRadius*2)
			love.graphics.line(points)
			-- draw a white line, to make the black actually look like an outline
			color()
			love.graphics.setLineWidth(cs.noteRadius*2-4)
			love.graphics.line(points)
			--the added line for mine holds
			if self.mineStripe then
				color('black')
				love.graphics.setLineWidth(cs.noteRadius*2-6)
				love.graphics.line(points)
				color()
			end
		elseif #points < 4 then
			error('not enough points!')
		end

		-- draw beginning and end of hold
		local xScale = cs.vfx.noteXScale or 1
		local yScale = cs.vfx.noteYScale or 1
		local xSkew = cs.vfx.noteXSkew or 0
		local ySkew = cs.vfx.noteYSkew or 0
		
		if self.tap and completion == 0 then
			self:drawTap(self.x,self.y,self.hb - cs.cBeat,xScale,yScale,xSkew,ySkew)
		end
		if self.endTap then
			self:drawTap(self.x2,self.y2,(self.hb + self.duration) - cs.cBeat,xScale,yScale,xSkew,ySkew)
		end
		color()
			
		if completion < 1 then
			if (not self.mineStripe) or (completion <= 0) then
				self:drawSprite(self.spr,self.x,self.y,0,xScale,yScale,xSkew,ySkew)
			end
			self:drawSprite(self.spr,self.x2,self.y2,0,xScale,yScale,xSkew,ySkew)
		end
		
		if self.mineStripe and (not cs.editMode) then
			love.graphics.draw(self.particleSys, project.res.cx, project.res.cy)
			if completion >= 1 then
				self:makeParticles(true)
			end
		end
		
		--[[
		color('black')
		love.graphics.print(segments,self.x,self.y)
		love.graphics.print(segments,self.x2,self.y2)
		]]--
	end, cs.outline)

	if self.mineStripe and (not cs.editMode) then
		love.graphics.draw(self.particle2Sys, project.res.cx, project.res.cy)
	end
	
  prof.pop('hold draw')
end

return Hold