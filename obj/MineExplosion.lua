MineExplosion = class('MineExplosion',Entity)

function MineExplosion:initialize(params)
  self.layer = 1
  self.upLayer = 9
  self.x = 0
  self.y = 0
  self.r = 0

  self.spr = sprites.note.mineexplosionparticle
  self.spr2 = sprites.note.mineholdparticle2
  self.particleSys = love.graphics.newParticleSystem(self.spr, 12)
  Entity.initialize(self,params)
  self:initParticleSys()
end

function MineExplosion:initParticleSys()
  self.particleSys:setParticleLifetime(10,10)
  self.particleSys:setEmitterLifetime(40)
  self.particleSys:setSpeed(2, 2)
  self.particleSys:setSizes(0.8, 0.5, 0)
  self.particleSys:setLinearDamping(0.15)
	local rand = love.math.random(45)
	for i=0,315,45 do
		self.particleSys:setDirection(math.rad(i+rand))
		self.particleSys:setRotation(math.rad(i+rand))
		self.particleSys:emit(1)
	end
	love.graphics.draw(self.particleSys,self.x,self.y,0,xScale,1)
	
	rand = love.math.random(90)
	--self.particleSys:setTexture(self.spr2)
	self.particleSys:setSpeed(0.5, 0.5)
	self.particleSys:setSizes(1.8, 1.2, 0)
	for i=45,315,90 do
		self.particleSys:setDirection(math.rad(i+rand))
		self.particleSys:setRotation(math.rad(i+180+rand))
		self.particleSys:emit(1)
	end
end

function MineExplosion:update(dt)
  prof.push("mineexplosion update")
  self.particleSys:update(dt)
  if self.particleSys:getCount() == 0 then
    self.delete = true
  end
  prof.pop("mineexplosion update")
end

function MineExplosion:draw()
  prof.push("mineexplosion draw")
	local xScale = 1
	outline(function()
		color()
		love.graphics.draw(self.particleSys,self.x,self.y,0,xScale,1)
	end, cs.outline)
  prof.pop("mineexplosion draw")
end

return MineExplosion