TitleParticle = class('TitleParticle',Entity)


function TitleParticle:initialize(params)
	
	self.layer = -10 -- lower layers draw first
	self.upLayer = 9 -- lower upLayer updates first
	self.x=-100
	self.y=-100
	self.dx = 1
	self.dy = 1
	
  Entity.initialize(self,params)
	
	local sprv = math.random(0,7)
	if sprv <= 5 then
		self.spr = sprites.note.square
	elseif sprv <= 6 then
		self.spr = sprites.note.inverse
	else
		self.spr = sprites.note.hold
	end
end

function TitleParticle:update(dt)
  prof.push("TitleParticle update")
  self.x = self.x + self.dx*dt
  self.y = self.y + self.dy*dt
  if self.y >= 300 then self.delete = true end -- i do not trust my deleting code at all
  prof.pop("TitleParticle update")

end


function TitleParticle:draw()
  prof.push("TitleParticle draw")
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(self.spr,self.x,self.y,0,1,1,8,8)
  prof.pop("TitleParticle draw")
end


return TitleParticle