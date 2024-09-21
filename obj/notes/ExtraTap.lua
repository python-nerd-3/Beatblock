ExtraTap = class ('ExtraTap', Block)

function ExtraTap:initialize(params)
	
	self.tap = true
	
	Block.initialize(self,params)
	
	self.layer = -10
	
	self.name = 'ExtraTap'
	
end

function ExtraTap:update(dt)
  prof.push('ExtraTap update')
	
  self:updateProgress()
	
	if self:checkIfActive() then
	
		if not self.hitYet then
			self.hitYet = true
			self:onHit()
		end
	
		if self.hitYet and self:checkTap() then
			self:cleanup()
		end
		
		if self:checkPassedWindow() then --missed window to tap in
			self:onMiss(true)
			self:cleanup()
		end
	end
	
  prof.pop('ExtraTap update')
end


function ExtraTap:onHit(mine, barely)
	if savedata.options.audio.hitsounds then
		te.playOne(sounds.tap,"static",'sfx',0.5)
	end
end

function ExtraTap:makeParticles(hit)
	--no particles, at least for now
	
end

function ExtraTap:draw(waveBeat)
	
	local verts = 16
	
  prof.push('ExtraTap draw')
	local innerPoly = {}
	local skipInner = false
	local outerPoly = {}
	
	waveBeat = waveBeat or (self.hb - cs.cBeat)
	local strength = 4
	
	
	
	for i=0,verts-1 do
		local x = math.sin(math.rad(i*(360/verts)))
		local y = math.cos(math.rad(i*(360/verts)))
		local waveOffset = math.sin(waveBeat*math.pi*2)*strength*(1-(i%2)*2)
		
		
		
		if not skipInner then
			local innerMult = ((self.hb - cs.cBeat)*cs.level.properties.speed*cs.scrollSpeed*self.sMult*-0.5)+cs.p:getDistance()+waveOffset
			if innerMult <= 6 then
				skipInner = true
			else
				table.insert(innerPoly,x*innerMult+self.ox)
				table.insert(innerPoly,y*innerMult+self.oy)
			end
		end
		
		local outerMult = ((self.hb - cs.cBeat)*cs.level.properties.speed*cs.scrollSpeed*self.sMult*1)+cs.p:getDistance()+waveOffset
		table.insert(outerPoly,x*outerMult+self.ox)
		table.insert(outerPoly,y*outerMult+self.oy)
		
	end
	love.graphics.setLineWidth(cs.vfx.extraTapWidth*self:getTapMult(cs.vfx.extraTapWidthPulse))
	
	outline(function()
		color(1)
		if not skipInner then
			love.graphics.polygon('line',innerPoly)
		end
		love.graphics.polygon('line',outerPoly)
		
	end, cs.outline)
	
  prof.pop('ExtraTap draw')
end

return ExtraTap