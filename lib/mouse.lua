--this game is so mouse-heavy that i think its worth it to move all this to its own file at this point

local mouse = {
	x = 0,
	y = 0, 
	pressed = 0, 
	altpress = 0, 
	dx = 0, 
	dy = 0,
	sx = 0,
	sy = 0,
	moved = false,
	circleSnap = false,
	inGameplay = false,
	mouseCanvas = love.graphics.newCanvas(project.res.x,project.res.y)
}

function mouse:enableGameplay()
	self.inGameplay = true
	if savedata.options.game.cursorMode ~= 'default' then
		love.mouse.setVisible(false)
	end
	if savedata.options.game.circleSnap then
		self.circleSnap = true
		love.mouse.setRelativeMode(true)
	end
	if savedata.options.game.lockMouseToWindow then
		love.mouse.setGrabbed(true)
	end
		
	
end

function mouse:disableGameplay()
	self.inGameplay = false
	self.circleSnap = false
	
	love.mouse.setVisible(true)
	love.mouse.setRelativeMode(false)
	love.mouse.setGrabbed(false)
end

function mouse:update()
  if self.pressed == -1 then
    self.pressed = 0
  end
  if love.mouse.isDown(1) then
    self.pressed = self.pressed + 1
  elseif self.pressed >=1 then
    self.pressed = -1
  else
    self.pressed = 0
  end
  
  
  if self.altpress == -1 then
    self.altpress = 0
  end
  if love.mouse.isDown(2) then
    self.altpress = self.altpress + 1
  elseif self.altpress >=1 then
    self.altpress = -1
  else
    self.altpress = 0
  end
  
	-- calculates aspect ratio of the monitor
	local gameRatio = project.res.x / project.res.y
	local gameSizeX = love.graphics.getHeight() * gameRatio
	self.x = (love.mouse.getX()/gameSizeX) - ((love.graphics.getWidth() - gameSizeX)/gameSizeX)/2 -- Subtracts the width of the black bars on their left/right of the screen from the X value. Fixes an issue where the game aspect ratio was not properly being respected while in fullscreen mode. - Bliv
	self.y = (love.mouse.getY()/love.graphics.getHeight())

  self.rx = self.x * project.res.x
  self.ry = self.y * project.res.y
	--print(self.rx .. " - " .. self.x)
end

function mouse:cleanup()
	self.sx, self.sy = 0,0
	if not self.moved then 
		self.dx, self.dy = 0,0
	end
	self.moved = false
end

function mouse:draw()
	if savedata.options.game.cursorMode == 'default' or (not self.inGameplay) or self.circleSnap then
		return
	end
	if love.joystick.getJoysticks()[1] and (not savedata.options.game.forceMouseKeyboard) then
		return
	end
	love.graphics.setCanvas(self.mouseCanvas)
	color()
	love.graphics.clear()
	love.graphics.draw(sprites.mouse, self.rx,self.ry,0,1,1,1,1)
	love.graphics.setCanvas()
	
	if savedata.options.game.cursorMode == 'invert' then
		love.graphics.setShader(shaders.cursor)
		shaders.cursor:send('shuvCanvas',shuv.canvasShaded)
	end
	love.graphics.draw(self.mouseCanvas,shuv.xoffset,shuv.yoffset,0,shuv.scale / shuv.internal_scale,shuv.scale / shuv.internal_scale)
	
	love.graphics.setShader()
end
	
return mouse