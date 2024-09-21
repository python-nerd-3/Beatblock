local st = Gamestate:new('InverseTutorial')

st:setInit(function(self)
	self.tutorial = ez.newjson('assets/game/inversetutorial'):instance()
	shuv.resetPal()
	shuv.pal[2] = {r=128,g=128,b=128}
end)


st:setUpdate(function(self,dt)
  self.tutorial:update(dt)
	if maininput:pressed("tap1") or maininput:pressed("accept") then
		te.stop('music')
		
		savedata.seenInverseTutorial = true
		sdfunc.save()
		
		cs = bs.load('Game')
		cs:init()
		
	end
end)

st:setBgDraw(function(self)
	color()
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
	self.tutorial:draw()
	love.graphics.setFont(fonts.digitalDisco)
	color(1)
	love.graphics.printf(loc.get('inverses_1'),10,30,(project.res.x-20)/2,'center',0,2,2)
	love.graphics.printf(loc.get('inverses_2'),10,250,(project.res.x-20)/2,'center',0,2,2)
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