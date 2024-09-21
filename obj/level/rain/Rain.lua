Rain = class('Rain',Entity)

function Rain:initialize(params)
  
  self.layer = 99 -- lower layers draw first
  self.upLayer = 99 --lower upLayer updates first
  self.x = 0
  self.y = 0
  
	self.dither = love.graphics.newImage('assets/ditherpatterns/1.png')
	
  Entity.initialize(self,params)
	
	self.bg = em.init('RainBG',{})
	self.bg.parent = self
	
	self.raindrops = {}
	
  self.color = 0
	self.speed = 1
	self.fallSpeed = 15
	self.baseCircleSpeed = 6
	self.baseAngle = 30
	
	self.spawnCooldown = 10
	self.spawnTimer = 0
end

function Rain:newRaindrop()
	local raindrop = {}
	raindrop.x = math.random(0,project.res.x)
	raindrop.y = math.random(0,project.res.y)
	raindrop.time = math.random(-40,-35)
	raindrop.endTime = math.random(20,25)
	raindrop.angle = self.baseAngle + math.random(-5,5)
	raindrop.circleSpeed = self.baseCircleSpeed + math.random(-2,2)
	
	
	table.insert(self.raindrops,raindrop)
end

function Rain:update(dt)
	
	self.spawnTimer = self.spawnTimer - dt * self.speed
	if self.spawnTimer <= 0 then
		self.spawnTimer = self.spawnCooldown
		self:newRaindrop()
	end
	
	
	local toRemove = {}
	for i,v in ipairs(self.raindrops) do
		v.time = v.time + dt * self.speed
		if v.time >= v.endTime then
			table.insert(toRemove, v)
		end
	end
	for i,v in ipairs(toRemove) do
		for _i,_v in ipairs(self.raindrops) do
			if _v == v then
				table.remove(self.raindrops, _i)
			end
		end
	end
end

function Rain:startStencil()
	color()
	love.graphics.setCanvas({love.graphics.getCanvas(),stencil = true})
	love.graphics.clear(false,true,false)
	love.graphics.setShader(shaders.texturestencil)
	love.graphics.stencil(function()
		love.graphics.draw(self.dither)
	end, 'replace', 1, true)
	love.graphics.setShader()
	love.graphics.setStencilTest('equal', 1)
	
end

function Rain:endStencil()
	love.graphics.setStencilTest()
	
end

function Rain:drawBG()
	self:startStencil()
	color(self.color)
	
	for i,v in ipairs(self.raindrops) do
		if v.time >= 1 then
			love.graphics.setLineWidth(((v.endTime - v.time) / v.endTime) * 5)
			love.graphics.circle('line',v.x,v.y,v.time * v.circleSpeed)
			love.graphics.circle('line',v.x,v.y,v.time * v.circleSpeed*0.2)
		end
	end
	self:endStencil()
end

function Rain:draw()
	self:startStencil()
	color(self.color)
	
	love.graphics.setLineWidth(2)
	for i,v in ipairs(self.raindrops) do
		if v.time <= 3 then
			local base = helpers.rotate(math.max(0,v.time * (-1 * self.fallSpeed)),v.angle,v.x,v.y)
			local top = helpers.rotate(math.max(1,(v.time+3) * (-1 * self.fallSpeed)),v.angle,v.x,v.y)
			love.graphics.line(base[1],base[2],top[1],top[2])
		end
		
	end
	
	self:endStencil()
end

return Rain