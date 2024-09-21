local st = Gamestate:new('IntroWarnings')

st:setInit(function(self)
	shuv.resetPal()
	self.screen = 0
	if savedata.seenIntroWarnings then
		cs = bs.load('Menu')
		cs:init()
	end
end)


st:setUpdate(function(self,dt)
	if maininput:pressed("tap1") or maininput:pressed("accept") then
		
		self.screen = self.screen + 1
		if self.screen == 2 then
			savedata.seenIntroWarnings = true
			sdfunc.save()
			
			cs = bs.load('Menu')
			cs:init()
		end
		
	end
end)

st:setBgDraw(function(self)
	color()
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
	--self.tutorial:draw()
	love.graphics.setFont(fonts.jfdot)
	color(1)
	love.graphics.printf(loc.get('attentionPls'),10,10,(project.res.x-20)/2,'center',0,2,2)
	if self.screen == 0 then
		love.graphics.printf(loc.get('epilepsyWarning'),10,90,(project.res.x-20)/2,'center',0,2,2)
	else
		love.graphics.printf(loc.get('demoWarning'),10,64,(project.res.x-20)/2,'center',0,2,2)
	end
	local locString = 'pressToContinue_mouse'
	if love.joystick.getJoysticks()[1] and (not savedata.options.game.forceMouseKeyboard)then 
		locString = 'pressToContinue_controller'
	end
	love.graphics.printf(loc.get(locString),10,320,(project.res.x-20)/2,'center',0,2,2)
end)
--entities are drawn here
st:setFgDraw(function(self)

end)

return st