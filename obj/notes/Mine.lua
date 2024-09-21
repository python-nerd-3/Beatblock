Mine = class ('Mine', Block)

function Mine:initialize(params)
	
	
	Block.initialize(self,params)
	
	self.name = 'mine'
	
	self.spr = animations.note.mine
end

function Mine:update(dt)
  prof.push('mine update')
	
  self:updateProgress()
  self:updateAngle()
  
	self:updatePositions()

  if self:checkIfActive() then
		local hit, barely = self:checkTouchingPaddle(self.endAngle)
		if hit and (not barely) then
			self:onMiss(true)
			cs.gm:handleMiss()
			self:cleanup()
		else
			self:onHit(true)
			cs.gm:addToScore(nil,nil,true,self.hb)
			self:cleanup()
		end
	end
	
  prof.pop('mine update')
end

return Mine