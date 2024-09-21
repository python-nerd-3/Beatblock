RainBG = class('RainBG',Entity)

function RainBG:initialize(params)
  
  self.layer = -80 -- lower layers draw first
  self.upLayer = 100 --lower upLayer updates first
  self.x = 0
  self.y = 0

end

function RainBG:update(dt)
end

function RainBG:draw()
	self.parent:drawBG()
end

return RainBG