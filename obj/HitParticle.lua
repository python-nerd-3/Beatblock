HitParticle = class('HitParticle',Entity)


function HitParticle:initialize(params)
	self.layer = -2
	self.upLayer = 9
	self.x = 0
	self.y = 0
	self.rad = 9
	
  Entity.initialize(self,params)
	
end

function HitParticle:update(dt)
  prof.push('HitParticle update')
  self.rad = self.rad - dt
  if self.rad <= 0 then
    self.delete = true
  end
  prof.pop('HitParticle update')
end


function HitParticle:draw()
  prof.push('HitParticle draw')
	
	outline(function()
		love.graphics.setLineWidth(1)
		color(1)
		love.graphics.circle("line",self.x,self.y,self.rad)
	end, cs.outline)
  prof.pop('HitParticle draw')
end


return HitParticle