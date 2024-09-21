local st = Gamestate:new('Credits')

st:setInit(function(self)
	entities = {}

	shuv.resetPal()
	shuv.pal[2] = {r=205,g=205,b=205}
	shuv.showBadColors = true
	self.tutorialBG = em.init('TutorialBG')
	self.tutorialBG.ySpeed = 0

	self.logoEase = nil
	self.logoZoom = 1
	self.logoY = 180
	
	self.ySpeed = 0
	self.y = 0
	
	self.bubbletabby = love.graphics.newImage('assets/bubbletabby.png')
	
	self.lines = {}
	for line in love.filesystem.lines('data/credits.txt') do
		table.insert(self.lines,line)
	end
	self.music = lovebpm.newTrack()
	self.music
		:load('assets/music/credits.ogg')
		:setBPM(90)
		:play()
		:setVolume(savedata.options.audio.musicvolume/10)
	
		
	rw:ease(8,1,'linear',{ySpeed = -0.4},self)
	
	rw:play(0)

end)

function st:returnToMenu()
	rw:stopAll()
	shuv.showBadColors = false
	self.music:stop()
	cs = bs.load('Menu')
	cs:init()
end

st:setUpdate(function(self,dt)
	self.music:update()
	rw:update(self.music:getBeat())
	
	self.tutorialBG.ySpeed = self.ySpeed * 0.5
	
	self.y = self.y + self.ySpeed * dt
	
	if maininput:pressed('back') then
		self:returnToMenu()
	end

end)


st:setBgDraw(function(self)

	love.graphics.setFont(fonts.digitalDisco)
	
	color()
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)



end)

st:setFgDraw(function(self)

	love.graphics.setFont(fonts.digitalDisco)
	
	color()
	love.graphics.draw(sprites.title.logo,project.res.cx,self.y + self.logoY,0,self.logoZoom, self.logoZoom,170,32)

	color(1)
	for i,v in ipairs(self.lines) do
		local x = 0
		local y = i * 32 + project.res.y + self.y
		if v == '!!bubbletabby!!' then
			color()
			love.graphics.draw(self.bubbletabby,project.res.cx,y,0,2,2,75,0)
		else
			love.graphics.printf(v,x,y,project.res.cx,'center',0,2,2)
		end
	end
	
	if self.y <= -2650 then
		color(1)
		local locString = 'returnToMenuPrompt_keyboard'
		if love.joystick.getJoysticks()[1] and (not savedata.options.game.forceMouseKeyboard)then 
			locString = 'returnToMenuPrompt_controller'
		end
		love.graphics.printf(loc.get(locString),0,330,project.res.cx,'center',0,2,2)
	end

end)


return st