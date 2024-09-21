Block = class('Block',Entity)

--all other beat types will now be separate selfects.

function Block:initialize(params)
	self.name = 'block'
	
	self.layer = 1
	self.upLayer = 3
	
	self.x = project.res.cx
	self.y = project.res.cy
	
  self.angle = 0
  self.drawAngle = 0
	
	self.sMult = 1
	
	self.hb = 0 --hit beat?
	
	self.moveTime = 0 --remaining time to hit
	
	self.progress = 0
	
	self.hitYet = false
	
  self.spr = animations.note.block
	
	self.hitSound = sounds.click
	
	self.spinEase = 'linear'
	
	self.inverse = false
	
	self.tap = self.tap or false
	--self.tapHit = false
	self.tapTimingWindow = 200
	
	self.barelyWindow = 30
	
	
  Entity.initialize(self,params)
	
	if self.inverse then
		self.spr = animations.note.inverse
		self.layer = 1
	else
	end
	
	self.positionOffset = 0
	
	self.startangle = self.startangle or self.angle
	self.endAngle = self.endAngle or self.angle
	
	if self.moveTime == 0 then
    self.moveTime = self.hb - cs.cBeat
  end
	
	self.ox = self.x
	self.oy = self.y
	
	if self.tap then
		self.tapManager = cs.gm:newTap(self.hb,false,self.tapTimingWindow)
	end
	
end


function Block:checkTap()
	if not self.tap then
		return true
	end
	return self.tapManager.hit
end

function Block:checkPassedWindow()
	if not self.tap then
		return false
	end
	return self.tapManager:passedWindow()
end

function Block:updateOrigin()
	if cs.vfx.notesFollowPlayer then
		self.ox, self.oy = cs.p.x, cs.p.y
	end
end

function Block:updateProgress()
  -- Progress is a number from 0 (spawn) to 1 (paddle)
  self.progress = 1 - ((self.hb - cs.cBeat) / self.moveTime)
	self:updateOrigin()
end

function Block:updateAngle()
	-- Interpolate angle between startangle and endAngle based on progress. Block should be at endAngle when it hits the paddle.
  if (self.hb - cs.cBeat) > 0 then --only clamp when moving towards point
    if self.spinEase == "linear" then --haha wow this should not be using an if statement???
			--todo: all the other eases
      self.angle = helpers.clamp(helpers.lerp(self.startangle, self.endAngle, self.progress), self.startangle, self.endAngle)
    elseif self.spinEase == "inExpo"  then
      --print(2 ^ (10 * (progress - 1)))
      self.angle = helpers.clamp(helpers.lerp(self.startangle, self.endAngle, 2 ^ (10 * (self.progress - 1))), self.startangle, self.endAngle)
    end
  end
end

function Block:getPositions()
	local invMul = 1
	local invOffset = 0
	if self.inverse and (not cs.editMode) then
		invMul = -1
		invOffset = cs.p.paddles[1].paddleWidth + cs.noteRadius*2-2
	end
	local distance = (self.hb - cs.cBeat)
	
	self.drawAngle = cs.gm:getVFXAngle(self.angle,distance)
	
	local speed = cs.level.properties.speed*cs.scrollSpeed*self.sMult
	
	if cs.editMode then
		speed = cs.zoom
	end
	
	local finalDistance = (distance*speed*invMul)+cs.p:getDistance()-self.positionOffset-invOffset
	
	if cs.editMode then
		finalDistance = finalDistance - cs.noteRadius + 1
	end
	
	return helpers.rotate(finalDistance,self.drawAngle,self.ox,self.oy)
end

function Block:updatePositions()
	local p1, p2 = self:getPositions()
	
  self.x = p1[1]
  self.y = p1[2]  
	if p2 then
		self.x2 = p2[1]
		self.y2 = p2[2]
	end
end

function Block:checkIfActive()
	return ((self.hb - cs.cBeat) <= 0)
end

function Block:checkTouchingPaddle(a)
  local angleOffset = 360 / cs.p.paddleCount
  local currentAngle = cs.p.angle
	--normal 
  for i = 1, #cs.p.paddles, 1 do
  local p = cs.p.paddles[i]
	if p.enabled then

		currentAngle = cs.p.angle - p.baseAngle

		if helpers.angdistance(a,currentAngle) <= p.paddleSize / 2 then
				return true, false
		elseif -- barely 
		helpers.angdistance(a,currentAngle) <= (p.paddleSize + self.barelyWindow) / 2 then
			return true, true
		end
  	end
	end
  return false, false
end

function Block:onHit(mine, barely)
	self:makeParticles(true)
	if mine then
		pq = pq .. "   player dodged " ..self.name.."!"
	else
		pq = pq .. "   player hit " ..self.name.."!"
	end
	
	if not mine then
		if self.tap and savedata.options.audio.hitsounds then
			te.playOne(sounds.tap,"static",'sfx',0.5)
		end
		if barely then
			if savedata.options.audio.hitsounds then
				te.playOne(self.hitSound,"static",'sfx',0.75)
			end
			te.playOne(sounds.barely,"static",'sfx',1.5)
		else
			
			if savedata.options.audio.hitsounds then
				te.playOne(self.hitSound,"static",'sfx')
			end
		end
		cs.p:doPaddleFeedback(self.inverse)
	end
	if cs.p.cEmotion == "miss" then
		cs.p.emoTimer = 0
		cs.p.cEmotion = "idle"
	end
end

function Block:onMiss(mine)
	if mine then
		self:makeParticles(true)
		pq = pq .. "   player hit " ..self.name.."!"
		
		te.playOne(sounds.mine,"static",'sfx')
	else
		self:makeParticles(false)
		pq = pq .. "   player missed " ..self.name.."!"
	end
		
	cs.p.emoTimer = 100
	cs.p.cEmotion = "miss"

	cs.p:hurtPulse()
end

function Block:makeParticles(hit)
	if hit then
    if self.name == "side" then 
      em.init("SideParticle", {x = self.x, y = self.y, r = self.angle,hitLeft = self.hitLeft})
		elseif self.name == "mine" then
			em.init("MineExplosion", {x = self.x, y = self.y})
    else
      em.init("HitParticle",{x = self.x, y = self.y})
    end
	else
		em.init("MissParticle",{
			x = project.res.cx,
			y = project.res.cy,
			angle = self.angle,
			distance = cs.p:getDistance() - self.positionOffset,
			spr = self.spr
		}):update()
	end
end

function Block:inTimingWindow(ms)
	return math.abs(self.hb - cs.cBeat) <= GameManager:msToBeat(ms/2)
end

function Block:update(dt)
  prof.push('beat update')
	
  self:updateProgress()
  self:updateAngle()
  
	self:updatePositions()
	if self:checkIfActive() then
	
		if not self.hitYet then
			local hit, barely = self:checkTouchingPaddle(self.endAngle)
			if cs.gm.noBarelyJudgements and barely then
				hit = false
				barely = false
			end
			if hit then
				self.hitYet = true
				cs.gm:addToScore(1, barely)
				self:onHit(false, barely)
			else
				self:onMiss() --missed note angle
				cs.gm:handleMiss()
				self:cleanup()
			end
		end
	
		if self.hitYet and self:checkTap() then
			self:cleanup()
		end
		
		if self:checkPassedWindow() then --missed window to tap in
			self:onMiss(true)
			self:cleanup()
		end
	end
	
  prof.pop('beat update')
end

function Block:cleanup()
	if self.tapManager then
		self.tapManager.delete = true
	end
	self.delete = true
end

function Block:drawSprite(s,x,y,r,sx,sy,kx,ky)
	local index = helpers.clamp(10 - math.floor(cs.noteRadius),0,4)
	s:draw(index,x,y,r,sx,sy,16,16,kx,ky)
end

function Block:getTapMult(strength)
	strength = strength or cs.vfx.tapPulseStrength 
	return 1 + (2^(-1*(cs.cBeat%cs.vfx.tapPulsePeriod)*(8/cs.vfx.tapPulsePeriod))) * (strength - 1)
end

function Block:drawTap(x,y,r,sx,sy,kx,ky)
	
	
	
	r = r or 0
	sx = sx or 1
	sy = sy or 1
	kx = kx or 0
	ky = ky or 0
	
	local tapMult = self:getTapMult()
	
	local radius1 = (cs.noteRadius + 2) * tapMult
	local radius2 = (cs.noteRadius + 4) * tapMult
	
	love.graphics.setLineWidth(self:getTapMult(cs.vfx.tapWidthPulse))
	
	
	love.graphics.push()
	color(1)
		love.graphics.translate(x+0.5,y+0.5)
		love.graphics.shear(kx,ky)
		love.graphics.rotate(math.rad(r*90))
		love.graphics.scale(sx,sy)
		love.graphics.rectangle('line',radius1*-1,radius1*-1,radius1*2-1,radius1*2-1)
	love.graphics.pop()
	
	love.graphics.push()
	color(1)
		love.graphics.translate(x+0.5,y+0.5)
		love.graphics.shear(kx,ky)
		love.graphics.rotate(math.rad(r*-90))
		love.graphics.scale(sx,sy)
		love.graphics.rectangle('line',radius2*-1,radius2*-1,radius2*2-1,radius2*2-1)
	love.graphics.pop()
	
end

function Block:draw()
  prof.push('beat (generic) draw')
	outline(function()
		local xScale = cs.vfx.noteXScale or 1
		local yScale = cs.vfx.noteYScale or 1
		local xSkew = cs.vfx.noteXSkew or 0
		local ySkew = cs.vfx.noteYSkew or 0
		
		if self.tap then
			self:drawTap(self.x,self.y,self.hb - cs.cBeat,xScale,yScale,xSkew,ySkew)
		end
		
		color()
		self:drawSprite(self.spr,self.x,self.y,0,xScale,yScale,xSkew,ySkew)
		
	end, cs.outline)

  prof.pop('beat (generic) draw')
	
	
end

return Block