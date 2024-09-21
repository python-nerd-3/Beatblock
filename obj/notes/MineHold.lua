MineHold = class ('MineHold', Hold)

function MineHold:initialize(params)
	
	
	Hold.initialize(self,params)
	
	self.mineStripe = true
	
	self.name = 'mine'
	self.tickRate = self.tickRate or 0.5
	self.lastHitBeat = nil
	
	self.spr = animations.note.minehold
	
	--for particles
	self.particleSpeed = math.min(cs.level.properties.speed*cs.scrollSpeed*self.sMult*GameManager:getBPM()/(22*165), 2.5)
	
	if (not cs.editMode) then
		self.particle1Image = sprites.note.mineholdparticle
		self.particleSys = love.graphics.newParticleSystem(self.particle1Image, 10000)
		self.particleSys:setParticleLifetime(0,24/self.particleSpeed)
		self.particleSys:setEmitterLifetime(-1)
		self.particleSys:setSpeed(self.particleSpeed)
		self.particleSys:setSizes(1, 0.75, 0)
		
		self.particle2Image = sprites.note.mineholdparticle2
		self.particle2Sys = love.graphics.newParticleSystem(self.particle2Image, 10000)
		self.particle2Sys:setParticleLifetime(4/self.particleSpeed,16/self.particleSpeed)
		self.particle2Sys:setEmitterLifetime(-1)
		self.particle2Sys:setSpeed(self.particleSpeed)
	end
	
	self.startParticleCreated = false
	self.endParticleCreated = false
	
	self.activeLastFrame = false
	self.movementDirectionLastFrame = 0
	
	self.lastParticleAngle = self.angle
	self.timeElapsedSinceLastParticle = 0
	self.radsPerParticle = 0.001
	self.radsPerSecRatio = 0.01 --at 100 BPM
	self.mineholdParticleSpawned = false
	self.currentParticlePos = 0
	self.angleLastFrame = self.angle
	
	self.lastX = self.x
	self.lastY = self.y
	
	if self.duration == 0 and (self.angle % 360 == self.angle2 % 360) then --ignore impossible "magic shape" mineholds
		self.unhittable = true
	end
	
end

function MineHold:checkTouchingPaddle()
	--want to check whether the paddle overlaps the region between the minehold's position last frame and current position
  for i = 1, #cs.p.paddles, 1 do
		local p = cs.p.paddles[i]
		if p.enabled then

			local currentAngle = cs.p.angle - p.baseAngle
			
			--if the center of the paddle is between [self.angle-p.paddleSize/2-angA,self.angle+p.paddleSize/2+angB]
			--the average of self.angle and self.angleLastFrame's distance from currentAngle is <= math.abs(self.angle-self.angleLastFrame)/2 + p.paddleSize/2
			
			if helpers.angdistance((self.angle+self.angleLastFrame)/2,currentAngle) <= math.abs(self.angle-self.angleLastFrame)/2 + p.paddleSize / 2 then
				return true
			end
		end
	end
	return false
end

function MineHold:direction(ax, ay, bx, by)
	--given two points A=(ax,ay) and B=(bx,by), finds the angle going from A to B
	--if B is directly above A this outputs 0
	--if B is directly right of A this outputs 90
	return math.atan2(by-ay, bx-ax)-math.pi/2
end

function MineHold:updateParticles(nextX, nextY)
	self.mineholdParticleSpawned = true
	--em.init("MineholdParticle", {x = self.x, y = self.y, r = self.angle})
	--self.nextParticleAngle = self.lastParticleAngle
	--self.timeElapsedSinceLastParticle
	
	--find some linear interp. between (self.lastParticleTime, self.lastParticleAngle)=(a,b) and
	--(self.lastParticleTime + self.timeElapsedSinceLastParticle, self.angle)=(c,d)
	--treat these as being cartesian, self.radsPerParticle = e, self.radsPerSecRatio = f, speed mult = s
	--then, sqrt((sf(c-a))^2+(d-b)^2) = rads between (a,b) and (c,d)
	--sqrt((sft(c-a))^2+(t(d-b))^2) = lerp rads between (a,b) and (c,d) using t
	--want to find some t such that sqrt((sft(c-a))^2+(t(d-b))^2) = e
	--t=e/sqrt((sf(c-a))^2+(d-b)^2)
	--then spawn a particle at (paddlerad, t(d-b)) and increment t until it's at 1
	
	--self.particleSys:setPosition(cs.p.x,cs.p.y)
	--self.particle2Sys:setPosition(cs.p.x,cs.p.y)
	
	local t = self.radsPerParticle/math.sqrt((self.particleSpeed*self.radsPerSecRatio*self.timeElapsedSinceLastParticle)^2+(math.rad(self.angle-self.lastParticleAngle))^2)
	if t<1 then
		self.timeElapsedSinceLastParticle = 0
	end
	local i = 0
	--helpers.interpolate(self.angle, self.angle2, angle_t, self.holdEase)
	while ((i+t) < 1) do
		i = i+t
		local currAngle = helpers.lerp(self.lastParticleAngle, self.angle, i)
		--move particleSys to cart(paddlerad, b+i(d-b))
		self.particleSys:setRotation(math.rad(currAngle))
		local direction = self:direction(self.x, self.y, nextX, nextY)
		
		local lifeFactor = 1-(helpers.angdistance(math.deg(direction)+180, currAngle)/90)*(1-(1/2)) --the "faster" the minehold moves, the less time the particles live, up to 1/2
		
		if self.duration == 0 then
			direction = math.rad(currAngle+90)
			lifeFactor = 2/3
		end
		local pos = helpers.rotate(cs.p:getDistance(), currAngle, 0,0)
		pos[1] = pos[1] + cs.p.x - project.res.cx
		pos[2] = pos[2] + cs.p.y - project.res.cy
		self.particleSys:setParticleLifetime(0,24*lifeFactor/self.particleSpeed)
		self.particle2Sys:setParticleLifetime(4*lifeFactor/self.particleSpeed,16*lifeFactor/self.particleSpeed)
		
		self.particleSys:setPosition(pos[1]+(-cs.noteRadius+self.currentParticlePos+1.3)*math.cos(direction)-1*math.sin(direction), pos[2]+(-cs.noteRadius+self.currentParticlePos+2)*math.sin(direction)+1*math.cos(direction))
		--self.particleSys:setEmissionArea("uniform", 0.01, 0, 0)
		self.particleSys:setDirection(math.rad(currAngle+90))
		
		self.particleSys:emit(1)
		
		self.currentParticlePos = self.currentParticlePos+1
		if self.currentParticlePos > 2*cs.noteRadius-3 then
			self.currentParticlePos = 0
		end
		
		--pos = helpers.rotate(cs.p:getDistance(), self.lastParticleAngle+i*(self.angle-self.lastParticleAngle), 0,0)
		self.particle2Sys:setDirection(math.rad(currAngle+90))
		local magnitude = 2.637 --making this bigger moves the white bands closer to the center
		if self.currentParticlePos % (cs.noteRadius-1) == 0 then
			self.particle2Sys:setPosition(pos[1]+(cs.noteRadius-magnitude)*math.cos(direction)-4*math.sin(direction), pos[2]+(cs.noteRadius-magnitude)*math.sin(direction)+4*math.cos(direction))
		elseif self.currentParticlePos % (cs.noteRadius-1) == math.floor(cs.noteRadius/2) then
			self.particle2Sys:setPosition(pos[1]-(cs.noteRadius-magnitude)*math.cos(direction)-4*math.sin(direction), pos[2]-(cs.noteRadius-magnitude)*math.sin(direction)+4*math.cos(direction))
		end
		self.particle2Sys:emit(1)
	end
	self.lastParticleAngle = self.lastParticleAngle+i*(self.angle-self.lastParticleAngle)
end

function MineHold:update(dt)
  prof.push('minehold update')
	
	self:updateProgress()
	self:updateAngle()
	
	self:updatePositions()
	
	local completion = ((self.hb - cs.cBeat)*-1)/self.duration
	
	local active = self:checkIfActive()
	if active then
		
		self:updateDuringHit()
		
		local hit = self:checkTouchingPaddle()
		
		if hit and ((completion <= 1) or (not self.activeLastFrame)) and (not cs.editMode) and (not self.unhittable) then 
			if not self.hitYet then
				self.hitYet = true
				self.lastHitBeat = math.floor(cs.cBeat / self.tickRate + 0.5) * self.tickRate
				
				self:onMiss(true)
				cs.gm:handleMiss()
				
				em.init("MineExplosion", {x = self.x, y = self.y})
			else
				local currentBeat = math.floor(cs.cBeat / self.tickRate) * self.tickRate
				if currentBeat > self.lastHitBeat then
					self.lastHitBeat = currentBeat
					
					self:onMiss(true)
					cs.gm:handleMiss()
					
					em.init("MineExplosion", {x = self.x, y = self.y})
					
					print('continued miss')
				end
			end
			--self:cleanup()
			
		end
		
		if completion >= 1 then
			if not self.hitYet then
				self:onHit(true)
				cs.gm:addToScore(nil,nil,true,self.hb+self.duration)
				self.hitYet = true
			end
			if ((self.hb - cs.cBeat)*-1)-self.duration >= 1 then
				self:cleanup()
			end
		end
	end
	
	if self.mineholdParticleSpawned then
		self.timeElapsedSinceLastParticle = self.timeElapsedSinceLastParticle + dt
		self.particleSys:update(dt)
		self.particle2Sys:update(dt)
	end
	
	self.angleLastFrame = self.angle
	self.activeLastFrame = active
	
  prof.pop('minehold update')
end

function MineHold:makeParticles(hit)
	if (not self.endParticleCreated) and (not cs.editMode) then
		em.init("MineExplosion",{x = self.x, y = self.y})
		if (((self.hb - cs.cBeat)*-1)/self.duration) >= 1 then
			self.endParticleCreated = true
		end
	end
end

return MineHold