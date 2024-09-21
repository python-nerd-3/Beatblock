Exampleentity = class('Exampleentity',Entity)

function Exampleentity:initialize(params)
  
  self.layer = 0 -- lower layers draw first
  self.upLayer = 0 --lower upLayer updates first
  self.x = 0
  self.y = 0
  
  self.sineTimer = 0
  
  self.r = 0
  
  self.spr = sprites.cat
  
  Entity.initialize(self,params)

end


function Exampleentity:update(dt)
  prof.push("example update")
  self.sineTimer = self.sineTimer + dt/60
  self.r = math.sin(self.sineTimer)*20
  prof.pop("example update")
end

function Exampleentity:draw()
  prof.push("example draw")
  color('white')
  love.graphics.draw(self.spr,self.x,self.y,math.rad(self.r),1,1,45,45)
  prof.pop("example draw")
end

return Exampleentity