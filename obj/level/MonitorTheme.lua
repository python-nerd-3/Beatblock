MonitorTheme = class('MonitorTheme',Entity)

function MonitorTheme:initialize(params)
  
  self.layer = -99 -- lower layers draw first
  self.upLayer = 99 --lower upLayer updates first
  self.x = 0
  self.y = 0
  
  self.spr = {}
	self.spr.top = love.graphics.newImage('assets/level/monitortheme/top.png')
	self.spr.lines = love.graphics.newImage('assets/level/monitortheme/lines.png')
	
	self.colorSwap = GameManager:getColorSwap(2,3,0,1)
  
  Entity.initialize(self,params)

end

function MonitorTheme:update(dt)
  self.y = (self.y + dt*0.25) % 6
end

function MonitorTheme:draw()
  prof.push("MonitorTheme draw")
	love.graphics.setCanvas(cs.vfx.effectCanvas)
	love.graphics.setColor(self.colorSwap/255,0,0,1)
	love.graphics.draw(self.spr.lines,0,self.y*-1,0,project.res.x,1)
	love.graphics.draw(self.spr.top)
  love.graphics.setCanvas(cs.canv)
	color()
  prof.pop("MonitorTheme draw")
end

return MonitorTheme