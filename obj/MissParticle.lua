MissParticle = class('MissParticle',Entity)


function MissParticle:initialize(params)
	self.layer = -2
	self.upLayer = 9
	self.x = project.res.cx
	self.y = project.res.cy
	self.ox, self.oy = cs.p.x, cs.p.y
	self.angle = 0
	self.distance = 42
	self.spr = love.graphics.newImage("assets/game/square.png")
	
  flux.to(self,15,{distance=0}):ease("outExpo"):oncomplete(function(f) self.delete=true end)
	
  Entity.initialize(self,params)
	
end



function MissParticle:update(dt)
  prof.push('MissParticle update')
	self.ox, self.oy = cs.p.x, cs.p.y
  local p1 = helpers.rotate(self.distance,self.angle,self.ox,self.oy)
  self.x = p1[1]
  self.y = p1[2]
  prof.pop('MissParticle update')
end


function MissParticle:draw()
  prof.push('MissParticle draw')
	outline(function()
		color()
		Block.drawSprite(self,self.spr,self.x,self.y)
	end, cs.outline)
  prof.pop('MissParticle draw')
end


return MissParticle