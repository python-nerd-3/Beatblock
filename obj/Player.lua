Player = class('Player',Entity)

function Player:initialize(params)

  self.layer = 0
  self.upLayer = 0
  self.spr = {
    idle = sprites.player.idle,
    happy = sprites.player.happy,
    miss = sprites.player.miss,
		angry = sprites.player.angry
  }
	self.spr[':3'] = sprites.player.colonthree
  self.x=0
  self.y=0
  self.bobI=0
  self.angle = 0
  self.anglePrevFrame = 0
	self.cumulativeAngle = nil
	self.angleDelta = 0
  self.extend = 0
	self.drawScale = 1
  self.outlineColor = 1
  self.fillColor = 0
	self.faceColor = -1
  self.cMode = (not love.joystick.getJoysticks()[1]) or savedata.options.game.forceMouseKeyboard
  self.cEmotion = "idle"
  self.emoTimer = 0
  self.paddleCount = 1
	self.paddleDistance = 31
  
  -- new paddle handling.
  -- why do i do this

  self.paddles = {}
  table.insert(self.paddles, self:newPaddle()) -- Adds default paddle

	for i=1, 7 do
		table.insert(self.paddles, self:newPaddle(false))
	end

  self.lookRadius = 6
	self.lookYOffset = 0
  self.maxBodyPulse = 0.2
	self.bodyRadius = 20
  self.bodyPulse = 0
  self.ouchTime = 15
	self.forceSprite = ''
	self.lineWidth = 2
	-- snap to circle-related stuff
	self.radius = 256 --radius of circle to snap to; inverse of sensitivity
	self.circleX = 0
	self.circleY = 0
	self.snapX = 0
	self.snapY = 0
	
	--feedback stuff
	self.feedbackTween = nil
	self.feedbackAmplitude = 2.5
	self.feedbackDuration = 4
	self.feedbackEase = 'outQuad'
	
	self.feedbackOffset = 0
	
	--self.arcTooBigTimer = 0
	--self.arcTooSmallTimer = 0
	self.transitionTween = nil
	
  Entity.initialize(self,params)
end

function Player:getDistance()
	return self.paddles[1].paddleWidth + self.paddleDistance + self.extend + cs.noteRadius - 1
end


function Player:growTransition(endFunction,zoomValue)
	zoomValue = zoomValue or self.drawScale * 0.9
	self.transitionTween = flux.to(self,20,{drawScale = zoomValue}):ease("outQuad"):oncomplete(function(f) 
		self.transitionTween = flux.to(self,60,{bodyPulse=10,drawScale = 30,lookRadius=0,lookYOffset=-30,lineWidth = 50}):ease("inQuint"):oncomplete(function(f) 
			if endFunction then endFunction() end
		end)
	end)
end

function Player:doPaddleFeedback(inverse)
	if self.feedbackTween then self.feedbackTween:stop() end
	
	self.feedbackOffset = self.feedbackAmplitude * -1
	if inverse then
		self.feedbackOffset = self.feedbackAmplitude
	end
	
	self.feedbackTween = flux.to(self,self.feedbackDuration,{feedbackOffset = 0}):ease(self.feedbackEase)
end

function Player:update(dt)
  prof.push("player update")
  self.angle = self.angle % 360
  self.emoTimer = self.emoTimer - dt
  if self.emoTimer <= 0 then
    self.cEmotion = "idle"
  end
	--[[
  if maininput:pressed("a") then
    self.cMode = not self.cMode
  end
	]]--
  if not cs.autoplay then
		self.anglePrevFrame = self.angle --this way obj.anglePrevFrame is always 1 frame behind obj.angle
		
    if (not mouse.circleSnap) and self.cMode then
			self.angle = 0-math.deg(math.atan2(self.y - mouse.ry, mouse.rx - self.x)) + 90
			
    elseif mouse.circleSnap then
			
			self.circleX = self.circleX + mouse.dx
			self.circleY = self.circleY + mouse.dy
			
			mouse.dx = 0
			mouse.dy = 0
			
			--print(mouse.dx .. ", " .. mouse.dy)
			
			if math.sqrt(self.circleX^2+self.circleY^2) ~= 0 then
				--normalize vector
				self.snapX = self.circleX / math.sqrt(self.circleX^2+self.circleY^2)
				self.snapY = self.circleY / math.sqrt(self.circleX^2+self.circleY^2)
			end
			--multiply by radius
			self.snapX = self.snapX * self.radius
			self.snapY = self.snapY * self.radius
			
			self.circleX = self.snapX
			self.circleY = self.snapY
			
			-- Below is scrapped code to make flicks easier, which I don't think we actually want (flicks are bad)
			-- If the mouse is moved inside of the circle
			--elseif (math.sqrt(self.circleX^2+self.circleY^2) < self.radius) and (self.circleX^2+self.circleY^2 ~= 0) and (mouse.dy^2+mouse.dx^2 ~= 0) then
			--	local tShorter
			--	local lineT1 = (-(self.circleX*mouse.dy-self.circleY*mouse.dx)+math.sqrt((self.circleX*mouse.dy-self.circleY*mouse.dx)^2-(mouse.dy^2+mouse.dx^2)*(self.circleX^2+self.circleY^2-self.radius^2)))/(mouse.dy^2+mouse.dx^2)
			--	local lineT2 = (-(self.circleX*mouse.dy-self.circleY*mouse.dx)-math.sqrt((self.circleX*mouse.dy-self.circleY*mouse.dx)^2-(mouse.dy^2+mouse.dx^2)*(self.circleX^2+self.circleY^2-self.radius^2)))/(mouse.dy^2+mouse.dx^2)
			--	local lineDist1 = math.sqrt((lineT1*mouse.dy)^2+(lineT1*mouse.dx)^2)
			--	local lineDist2 = math.sqrt((lineT2*mouse.dy)^2+(lineT2*mouse.dx)^2)
			--	if lineDist1 < lineDist2 then
			--		tShorter = lineT1
			--	else
			--		tShorter = lineT2
			--	end
			--	self.circleX = self.circleX + tShorter*mouse.dy
			--	self.circleY = self.circleY - tShorter*mouse.dx
			--end
			
			self.angle = math.atan2(self.circleY, self.circleX) * 180 / math.pi + 90
			
			--tells you in console if your arc is too big or small
			--if math.sqrt(self.circleX^2+self.circleY^2) < self.radius then
			--	self.arcTooBigTimer = 0
			--	self.arcTooSmallTimer = self.arcTooSmallTimer + 1
			--elseif math.sqrt(self.circleX^2+self.circleY^2) > self.radius then
			--	self.arcTooBigTimer = self.arcTooBigTimer + 1
			--	self.arcTooSmallTimer = 0
			--else
			--	self.arcTooBigTimer = 0
			--	self.arcTooSmallTimer = 0
			--end
			
			--if self.arcTooBigTimer > 4 then
			--	print ("Your arc is too big!")
			--elseif self.arcTooSmallTimer > 12 then
			--	print ("Your arc is too small!")
			--end
			
			--print(self.arcTooSmallTimer)
			
		else
      if love.joystick.getJoysticks()[1] then
        self.anglePrevFrame = self.angle
				local y = love.joystick.getJoysticks()[1]:getAxis(2)
				local x = love.joystick.getJoysticks()[1]:getAxis(1)
				if math.sqrt(x^2+y^2) >= 0.2 then
				
					self.angle = math.deg(math.atan2(y,x))+90
				end
      end
			
    end
		
		local angleDifference = self.angle - self.anglePrevFrame
		local angleCap = math.max(15,self.paddles[1].paddleSize)
		
		angleDifference = (angleDifference + 180) % 360 - 180
		
		if angleDifference > angleCap then
			self.angle = self.anglePrevFrame + angleCap
		end
		if angleDifference < -angleCap then
			self.angle = self.anglePrevFrame - angleCap
		end
			
  end
	self.angleDelta = helpers.angdelta(self.anglePrevFrame,(self.angle+360)%360)
	if self.cumulativeAngle then
		self.cumulativeAngle = self.cumulativeAngle + self.angleDelta
	else
		self.cumulativeAngle = self.angle
	end
  self.bobI = self.bobI + 0.03*dt
  prof.pop("player update")
end

function Player:savePaddleSize() --paddle size needs to be saved *before* eases are run, so we'll run it outside of update()
	for i = 1, #self.paddles do
		self.paddles[i].paddleSizePrevFrame = self.paddles[i].paddleSize
	end
end

function Player:draw()
	outline(function()
		love.graphics.setLineWidth(self.lineWidth/self.drawScale)
		
		local paddleFeedbackPosition = helpers.rotate(self.feedbackOffset, self.angle,self.x,self.y)
		
		for i = 1, #self.paddles, 1 do
			local p = self.paddles[i]
			if p.enabled then
				-- draw the paddle
				love.graphics.push()
				love.graphics.translate(paddleFeedbackPosition[1],paddleFeedbackPosition[2])
				love.graphics.rotate((self.angle - p.baseAngle - 90) * math.pi / 180)
				love.graphics.scale(self.drawScale)
				--HANDLE
				--fill in handle
        color(self.fillColor)
				local tempPaddleDistance = self.paddleDistance

				if i <= 1 then

					if p.paddleSize < 20 and p.handleSize > 0.5*p.paddleSize then
						p.handleSize = math.floor(p.paddleSize/2)
					end

					local dist = tempPaddleDistance + self.extend + p.paddleWidth * 0.5
					local x1 = dist * math.cos(p.handleSize * math.pi / 180)
					local y1 = dist * math.sin(p.handleSize * math.pi / 180)
					local x2 = dist * math.cos(-p.handleSize * math.pi / 180)
					local y2 = dist * math.sin(-p.handleSize * math.pi / 180)
					love.graphics.polygon('fill',0,0, x1,y1, x2,y2)
					color(self.outlineColor)
					-- draw handle lines
					love.graphics.line(0,0, x1,y1)
					love.graphics.line(0,0, x2,y2)
				end


				--PADDLE
				local paddleAngle = helpers.clamp(p.paddleSize,0,360) / 2
				local paddlePoly = {}
				local segments = 10
				local function addVert(pos)
					table.insert(paddlePoly,pos[1])
					table.insert(paddlePoly,pos[2])
				end
				for i=0,segments-1 do
					addVert(helpers.rotate((self.paddleDistance + self.extend), helpers.lerp(paddleAngle, -paddleAngle, i/(segments-1))+90,0,0))
				end

				for i=0,segments-1 do
					addVert(helpers.rotate((self.paddleDistance + self.extend)+ p.paddleWidth, helpers.lerp(paddleAngle, -paddleAngle, 1-i/(segments-1))+90,0,0))
				end

				color(self.fillColor)
				pcall(function()
					--quick hack to prevent gritted crash on mac, investigate further!
					for i,v in ipairs(love.math.triangulate(paddlePoly)) do
						love.graphics.polygon('fill',v)
					end
					
					color(self.outlineColor)
					love.graphics.polygon('line',paddlePoly)
				end)
				love.graphics.pop()
			end
		end

		love.graphics.push()
			-- scaling circle and face for hurt animation
			local bodyPulseScale = (1 + self.bodyPulse) *self.drawScale
			love.graphics.scale(bodyPulseScale)
			love.graphics.setLineWidth(self.lineWidth/bodyPulseScale)

			-- adjusting x and y so they're unaffected by scaling
			local finalX = self.x / bodyPulseScale
			local finalY = self.y / bodyPulseScale

			-- draw the circle
			color(self.fillColor)
			love.graphics.circle("fill",finalX,finalY,self.bodyRadius+self.extend/2+(math.sin(self.bobI))/2)
			color(self.outlineColor)
			love.graphics.circle("line",finalX,finalY,self.bodyRadius+self.extend/2+(math.sin(self.bobI))/2)
      
			-- draw the eyes
			if self.faceColor ~= -1 then
				color(self.faceColor)
				love.graphics.setShader(shaders.recolor)
			else
				color()
			end
			if self.forceSprite ~= 'none' then
				-- determine x and y offsets of the eyes
				local eyex = (self.lookRadius) * math.cos((self.angle - 90) * math.pi / 180)
				local eyey = (self.lookRadius) * math.sin((self.angle - 90) * math.pi / 180)
				local faceSpr = self.spr[self.cEmotion]
				if self.forceSprite ~= '' then
					faceSpr = self.spr[self.forceSprite]
				end
				love.graphics.draw(faceSpr,finalX + eyex,finalY + eyey + self.lookYOffset,0,1,1,faceSpr:getWidth()/2,faceSpr:getHeight()/2)
			end
			if self.faceColor ~= -1 then
				love.graphics.setShader()
			end
		love.graphics.pop()
	end, cs.outline)
	
end


function Player:hurtPulse()
  self.bodyPulse = self.maxBodyPulse
  flux.to(self,self.ouchTime,{bodyPulse=0}):ease("outSine")
end

function Player:newPaddle(enabled, width, size, baseAngle)

	local paddleID = #self.paddles

	if enabled == nil then
		enabled = true
	end

	width = width or 11
	size = size or 70
	local sizePrevFrame = size
	baseAngle = baseAngle or 0
	local handleSize = 10

	return {paddleID = paddleID, enabled = enabled, paddleWidth = width, paddleSize = size, paddleSizePrevFrame = sizePrevFrame, baseAngle = baseAngle, handleSize = handleSize}
end

return Player