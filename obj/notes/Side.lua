Side = class ('Side', Block)

function Side:initialize(params)
	
	self.sideHitYet = false
  self.leftHit = false
	self.sideTimingWindow = 200 -- should be ~1/4 of a beat at lawrence's BPM
	if savedata.options.accessibility.sides == 'lenient' then
		self.sideTimingWindow = 400
	end
	self.skipoverWindow = 80 -- changed from 60, now you simply have to be on the same side
	
	Block.initialize(self,params)
	
	self.name = 'side'
	self.spr = animations.note.side
	--self.hitSound = sounds.side
	
	self.hitsoundPlayed = false
end

function Side:playHitSFX()
	if self.tap and savedata.options.audio.hitsounds then
		te.playOne(sounds.tap,"static",'sfx',0.5)
	end
	if savedata.options.audio.hitsounds then
		te.playOne(self.hitSound,"static",'sfx')
	end
end

function Side:onHit()
	self:makeParticles(true)
	
	if (not self.hitsoundPlayed) then
		self.hitsoundPlayed = true
		self:playHitSFX()
	end
	
	--if barely then
	--	if savedata.options.audio.hitsounds then
	--		te.playOne(self.hitSound,"static",'sfx',0.75)
	--	end
	--	te.playOne(sounds.barely,"static",'sfx',1.5)
	--else
	
	--end
	if cs.p.cEmotion == "miss" then
		cs.p.emoTimer = 0
		cs.p.cEmotion = "idle"
	end
end

function Side:update(dt) --todo: split this into functions, so other beat types can use this code
  prof.push('side update')
	
  self:updateProgress()
  self:updateAngle()
  
	self.positionOffset = cs.p.paddles[1].paddleWidth/2 + cs.noteRadius -- bliv: idk what this line does, but i did this as a jank fix for multi-paddle implementation. it's probably fine.
	self:updatePositions()
	
	local timeUntil = self.hb - cs.cBeat --positive = hasnt arrived yet, negative = has arrived
	local active = self:inTimingWindow(self.sideTimingWindow)
	local hitHeadOn = false
	for i = 1, #cs.p.paddles, 1 do

		local p = cs.p.paddles[i]
		if p.enabled then
			local nowDistance = helpers.angdistance(self.angle,cs.p.angle - p.baseAngle)
			local prevDistance = helpers.angdistance(self.angle,cs.p.anglePrevFrame - p.baseAngle)
			--print(nowDistance, prevDistance)
			local hitThisFrame = (nowDistance <= p.paddleSize / 2) -- if the player is currently hitting the sidebeat
			local hitLastFrame = (prevDistance <= p.paddleSizePrevFrame / 2) --if the player was hitting the sidebeat last frame
			
			--local nowLeft = ((self.angle - cs.p.angle + p.baseAngle) < 0 or (self.angle - cs.p.angle - p.baseAngle) > 180) 
			--local prevLeft = ((self.angle - cs.p.anglePrevFrame + p.baseAngle) < 0 or (self.angle - cs.p.anglePrevFrame - p.baseAngle) > 180) 
			local nowLeft = helpers.angdelta(cs.p.angle + p.baseAngle,self.angle) >=0 
			local prevLeft = helpers.angdelta(cs.p.anglePrevFrame + p.baseAngle,self.angle) >=0 
			
			hitHeadOn = hitThisFrame and hitLastFrame
			
			if not self.sideHitYet and active then
				if hitThisFrame and (not hitLastFrame) then
					self.sideHitYet = true
					if helpers.angdelta(cs.p.angle + p.baseAngle,cs.p.anglePrevFrame + p.baseAngle)>= 0 then
						self.hitLeft = true
					else
					end
				end
				if (not hitThisFrame) and (not hitLastFrame) and nowDistance <= self.skipoverWindow and prevDistance <= self.skipoverWindow then -- this accounts for situations where the player skips over the note
					if prevLeft then --was the player to the left of the note last frame?
						if not nowLeft then --is the player to the right of the note this frame? (left to right)
							self.sideHitYet = true
							self.hitLeft = false
						end
					else
						if nowLeft then --is the player to the left of the note this frame? (right to left)
							self.sideHitYet = true
							self.hitLeft = true
						end
					end
				end

			end
		end
	end
	
	--make head on hits count in lenient mode
	if savedata.options.accessibility.sides == 'lenient' and hitHeadOn then 
		hitHeadOn = false
		self.sideHitYet = true
	end
	
	if savedata.options.accessibility.sides == 'auto' and not self.sideHitYet then
		self.sideHitYet = true
	end
	
	
	
	if timeUntil <= 0 then -- don't "judge" the player until the beat has passed
		if self.sideHitYet then
			if self:checkTap() then
				self:onHit()
				cs.gm:addToScore()
				self:cleanup()
			else
				if self:checkPassedWindow() then --missed tap input
				self:onMiss(true)
				self:cleanup()
				end
			end
		else
			if (not active) then --if it is not hit at all
				self:onMiss()
				cs.gm:handleMiss()
				self:cleanup()
			elseif hitHeadOn  then --if the beat is hit head on
				self:onMiss(true)
				cs.gm:handleMiss()
				self:cleanup()
			end
		end
		
		if (not self.hitsoundPlayed) then
			self.hitsoundPlayed = true
			self:playHitSFX()
		end
	end
	
	prof.pop('side update')
end

function Side:drawTap(x,y,r,b)
	
	love.graphics.setLineWidth(self:getTapMult(cs.vfx.tapWidthPulse))
	
	local tapMult = self:getTapMult()
	
	local vRadius = (cs.noteRadius + 6) * tapMult
	local hRadius = vRadius / 2.5
	
	local xOffset = math.sin(b*math.pi)*hRadius
	
	love.graphics.push()
		color(1)
		love.graphics.translate(x+0.5,y+0.5)
		--love.graphics.shear(kx,ky)
		love.graphics.rotate(math.rad(r))
		--love.graphics.scale(sx,sy)
		love.graphics.rectangle('line',hRadius*-1+xOffset,vRadius*-1,hRadius*2-1,vRadius*2-1)
		love.graphics.rectangle('line',hRadius*-1-xOffset,vRadius*-1,hRadius*2-1,vRadius*2-1)
	love.graphics.pop()


end


function Side:draw()
	prof.push('side draw')
	outline(function()
		

		
		color()
		self:drawSprite(self.spr,self.x,self.y,math.rad(self.angle))
		
		if self.tap then
			self:drawTap(self.x,self.y,self.angle,self.hb - cs.cBeat)
		end
	end, cs.outline)
	prof.pop('side draw')
end

return Side