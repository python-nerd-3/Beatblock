Tutorial = class('Tutorial',Entity)

function Tutorial:initialize(params)
  
  self.layer = 10 -- lower layers draw first
  self.upLayer = 99 --lower upLayer updates first
  self.x = 0
  self.y = 0
  self.text = ''
	
	self.blockTap = {
		spr = animations.note.block,
		hb = 0,
		x=-150,
		y=180,
		tap = true,
		
		getTapMult = Block.getTapMult,
		drawTap = Block.drawTap,
		drawSprite = Block.drawSprite
	}
	
	self.extraTap = {
		hb = 0,
		ox = 750,
		oy = 180,
		sMult = 1,
		getTapMult = Block.getTapMult
	}
	
	self.tapsX = 0
	
	self.drawTaps = false
	
  Entity.initialize(self,params)
	
	

end

function Tutorial:update(dt)
  prof.push("Tutorial update")
	local h = 1.5
	self.extraTap.hb = math.ceil(cs.cBeat/2)*2 + (cs.cBeat%2)*(h/2) - h
	
	
	
  prof.pop("Tutorial update")
end

function Tutorial:draw()
  prof.push("Tutorial draw")
  color(1)
	--just for this, we're gonna increase line height.
	fonts.digitalDisco:setLineHeight(1)
	
	love.graphics.setFont(fonts.digitalDisco)
	love.graphics.printf(self.text,0,10+self.y,project.res.x/2,'center',0,2,2)
	
	self.blockTap.x = -150 + self.tapsX * 300
	self.extraTap.ox = 750 - self.tapsX * 300
	if self.drawTaps then
		Block.draw(self.blockTap)
		ExtraTap.draw(self.extraTap,cs.cBeat)
	end
		--reset
	fonts.digitalDisco:setLineHeight(0.75)
	
  prof.pop("Tutorial draw")
end

return Tutorial