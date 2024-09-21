Deco = class('Deco',Entity)

function Deco:initialize(params)
	self.layer = 999
	self.upLayer = 9
	
	self.sprite = ''
	self.spr = sprites.cat
	
	self.x = project.res.cx
	self.y = project.res.cy
	self.r = 0
	self.sx = 1
	self.sy = 1
	self.ox = 0
	self.oy = 0
	self.kx = 0
	self.ky = 0
	self.drawLayer = 'fg'
	self.drawOrder = 0
	self.recolor = -1
	self.outline = false
	self.effectCanvas = false
	self.effectCanvasRaw = true
	self.hide = false
	
	self.anim = nil
	self.animFrame = nil
	self.animSpeed = nil
	
	self.hasMoved = false
	
  Entity.initialize(self,params)
	
end

function Deco:updateSprite()
	if self.drawLayer == 'fg' then
		self.layer = 999
	elseif self.drawLayer == 'bg' then
		self.layer = -999
	else
		self.layer = 0
	end
	self.layer = self.layer + self.drawOrder
	self.spr = cs.vfx.decoSprites[self.sprite] or sprites.cat
	self.hasMoved = true
end

function Deco:update(dt)
  prof.push('Deco update')
	if self.anim then
		self.anim:update(dt,self.animSpeed)
	end
  prof.pop('Deco update')
end

function Deco:drawMain(skipSetColor)
	if not skipSetColor then
		if self.recolor ~= -1 then
			color(self.recolor)
			love.graphics.setShader(shaders.recolor)
		else
			color()
		end
	end

	if self.anim then
		if self.animFrame then
			self.anim:drawFrame(self.animFrame,self.x,self.y,math.rad(self.r),self.sx,self.sy,self.ox,self.oy,self.kx,self.ky)
		else
			self.anim:draw(self.x,self.y,math.rad(self.r),self.sx,self.sy,self.ox,self.oy,self.kx,self.ky)
		end
	else
		love.graphics.draw(self.spr,self.x,self.y,math.rad(self.r),self.sx,self.sy,self.ox,self.oy,self.kx,self.ky)
	end
	
	
	if self.recolor ~= -1 then
		color()
		love.graphics.setShader()
	end
end

function Deco:draw(isOnTop)
  prof.push('Deco draw')
	
	if (not self.hasMoved) or self.hide or (self.drawLayer == 'ontop' and (not isOnTop)) then
		prof.pop('Deco draw')
		return
	end
	
	if self.effectCanvas then
		local oldCanvas = love.graphics.getCanvas()
		love.graphics.setCanvas(cs.vfx.effectCanvas)
		if self.effectCanvasRaw then
			color()
			self:drawMain(true)
		else
			--calculate new color here
			self:drawMain(true)
			
		end
		love.graphics.setCanvas(oldCanvas)
	else
		if self.outline then
			outline(function() self:drawMain() end, cs.outline)
		else
			self:drawMain()
		end
	end

  prof.pop('Deco draw')
end


return Deco