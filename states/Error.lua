local st = Gamestate:new('Error')

st:setInit(function(self)
	self.errorMessage = self.errorMessage or 'No error provided???'
	self.errorSprite = ez.newjson('assets/error/error'):instance()
	shuv.resetPal()
	te.play('assets/music/caution.ogg','stream','music')
end)


st:setUpdate(function(self,dt)
  self.errorSprite:update(dt)
	if maininput:pressed("accept") or maininput:pressed("back")then
		te.stop('music')
		
		cs = bs.load(returnData.state)
		for k,v in pairs(returnData.vars) do
			cs[k] = v
		end
		cs:init()
		
	end
end)

st:setBgDraw(function(self)
	color()
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
	self.errorSprite:draw()
	love.graphics.setFont(fonts.main)
	color(1)
	local locString = 'returnToMenuPrompt_keyboard'
	if love.joystick.getJoysticks()[1] and (not savedata.options.game.forceMouseKeyboard) then 
		locString = 'returnToMenuPrompt_controller'
	end
	love.graphics.printf(loc.get('errorMessage',{self.errorMessage})..'\n\n'..loc.get(locString),10,124,(project.res.x-20)/2,'center',0,2,2)
end)
--entities are drawn here
st:setFgDraw(function(self)

end)

return st