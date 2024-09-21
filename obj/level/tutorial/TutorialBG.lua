TutorialBG = class('TutorialBG',Entity)

function TutorialBG:initialize(params)
  
  self.layer = -99 -- lower layers draw first
  self.upLayer = 99 --lower upLayer updates first
  self.x = 0
  self.y = 0
  
	self.ySpeed = 0.1
	
  self.sineTimer = 0
  
  self.spr = {}
	self.spr.line0 = love.graphics.newImage('assets/level/tutorial/line0.png')
	self.spr.line1 = love.graphics.newImage('assets/level/tutorial/line1.png')
  
  Entity.initialize(self,params)


end

function TutorialBG:update(dt)
  prof.push("TutorialBG update")
	
  self.sineTimer = self.sineTimer + dt/60
	self.y = self.y - dt*self.ySpeed
	
  prof.pop("TutorialBG update")
end

function TutorialBG:draw()
  prof.push("TutorialBG draw")
  color(2)
	for i = 0,21 do
		local y = i * 20 - (self.y%80) 
		
		if i % 2 == 0 then
			love.graphics.draw(self.spr.line0,5,y)
		else
			
			local x = math.sin(self.sineTimer)*20
			
			if i % 4 == 1 then
				x = x * -1
			end
			love.graphics.draw(self.spr.line1,(x % 20) - 15,y)
			
		end
	end
  prof.pop("TutorialBG draw")
end

return TutorialBG