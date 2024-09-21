LawrenceBG = class('LawrenceBG',Entity)

function LawrenceBG:initialize(params)
  
  self.layer = -99 -- lower layers draw first
  self.upLayer = 99 --lower upLayer updates first
  self.x = 0
  self.y = 0
  
  self.sineTimer = 0
  
  self.r = 0
	--self.playerOffset = 0
	self.cumulativeAngle = 0 
	self.rotateMix = 0
  
	
  self.spr = {}
	self.spr.gear = love.graphics.newImage('assets/level/lawrence/gear.png')
	self.spr.ring = love.graphics.newImage('assets/level/lawrence/ring.png')
	
	self.sections = {}
	self.sections[0] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[1] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[2] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[3] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[4] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[5] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[6] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	self.sections[7] = {spr = 'ring',rPlayer = 0, r= 0, scale = 0}
	
	self.offset = 0
	self.offsetEased = 0
	
	self.zoom = 1
	self.zoomOffset = 0.75
  
  Entity.initialize(self,params)

end

function LawrenceBG:addSection(sprite,depth)
end

function LawrenceBG:resetPlayerRot()
	self.cumulativeAngle = 720
	--self.playerOffset = (math.floor(cs.p.cumulativeAngle / 360) * -360) + 720
end

function LawrenceBG:changeOffset(offsetDelta,beat,duration,ease)
	ease = ease or 'outExpo'
	duration = duration or 2
	self.offset = self.offset + offsetDelta
	rw:easenow(beat,2,'outExpo',self.offset,self,'offsetEased')
end

function LawrenceBG:update(dt)
  prof.push("LawrenceBG update")
	local sineTimerOld = self.sineTimer
  self.sineTimer = self.sineTimer + dt/60
	local sineDelta = math.sin(sineTimerOld)*20 - math.sin(self.sineTimer)*20
	
	
	
	self.cumulativeAngle = self.cumulativeAngle + cs.p.angleDelta
	local oldR = self.r
  self.r = (1 - self.rotateMix) * math.sin(self.sineTimer)*20 + (self.rotateMix) * (self.cumulativeAngle)
	local rDelta = self.r - oldR
	
	
	--self.offsetEased = self.offsetEased + 0.01 * dt
	
	for k,v in pairs(self.sections) do
		local offset = (k+self.offset) % 8
		local offsetEased = (k+self.offsetEased) % 8
		local rotateDiv = 2^offset
		local scale = 2^offsetEased
		if offsetEased < 1 then
			rotateDiv = math.sqrt(offset)*2
			scale = math.sqrt(offsetEased)*2
			--print(rotateDiv)
		end
		scale = scale * (3/16)
		v.scale = (scale - self.zoomOffset) * self.zoom + self.zoomOffset
		
		v.r = v.r + rDelta / rotateDiv
		
		if v.scale <= 0.1 then
			v.r = 0
		end
	end
	
  prof.pop("LawrenceBG update")
end

function LawrenceBG:draw()
  prof.push("LawrenceBG draw")
  color(3)
	--[[
  love.graphics.draw(self.spr.ring,self.x,self.y,math.rad(self.r/2),0.375,0.375,256,256)
  love.graphics.draw(self.spr.gear,self.x,self.y,math.rad(self.r/4),0.75,0.75,256,256)
  love.graphics.draw(self.spr.ring,self.x,self.y,math.rad(self.r/8),1.5,1.5,256,256)
	]]
	
	for k,v in pairs(self.sections) do
		love.graphics.draw(self.spr[v.spr],self.x,self.y,math.rad(v.r),v.scale,v.scale,256,256)
	end
  prof.pop("LawrenceBG draw")
end

return LawrenceBG