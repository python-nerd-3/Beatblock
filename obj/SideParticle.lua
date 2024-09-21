SideParticle = class('SideParticle',Entity)

function SideParticle:initialize(params)
  self.layer = -2 
  self.upLayer = 9
  self.x = 0
  self.y = 0
  self.r = 0
  
  self.spr = sprites.note.sideparticle
  self.particleSys = love.graphics.newParticleSystem(self.spr, 6)
  Entity.initialize(self,params)
  self:initParticleSys()
end

function SideParticle:initParticleSys()
  self.particleSys:setParticleLifetime(20,40)
  self.particleSys:setEmitterLifetime(40)
  self.particleSys:setSpeed(7, 15)
  self.particleSys:setSpread(0.4)
  self.particleSys:setSizes(1, 0.75, 0)
  self.particleSys:setLinearDamping(0.15)
  self.particleSys:emit(6)
end

function SideParticle:update(dt)
  prof.push("sideparticle update")
  self.particleSys:update(dt)
  if self.particleSys:getCount() == 0 then
    self.delete = true
  end
  prof.pop("sideparticle update")
end

function SideParticle:draw()
  prof.push("sideparticle draw")
	local xScale = 1
	local r = self.r
	if self.hitLeft then
		xScale = -1
		r = r - 8
	else
		r = r + 8
	end
	outline(function()
		outline(function()
			color()
			love.graphics.draw(self.particleSys,self.x,self.y,math.rad(r),xScale,1)
		end, 1)
	end, cs.outline)
  prof.pop("sideparticle draw")
end

return SideParticle