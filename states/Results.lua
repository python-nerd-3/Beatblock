local st = Gamestate:new('Results')

st:setInit(function(self)
	entities = {}

	self.canv = love.graphics.newCanvas(project.res.x,project.res.y)
	shuv.resetPal()
	if self.level.metadata.bg and self.level.metadata.bgData.image ~= '' and love.filesystem.exists(cLevel .. self.level.metadata.bgData.image) then
		self.bgImage = love.graphics.newImage(cLevel .. self.level.metadata.bgData.image)
		shuv.pal[2] = self.level.metadata.bgData.redChannel
		shuv.pal[3] = self.level.metadata.bgData.blueChannel
		shuv.pal[4] = self.level.metadata.bgData.greenChannel or {r=255,g=255,b=255}
		shuv.pal[5] = self.level.metadata.bgData.yellowChannel or {r=255,g=255,b=255}
		shuv.pal[6] = self.level.metadata.bgData.magentaChannel or {r=255,g=255,b=255}
		shuv.pal[7] = self.level.metadata.bgData.cyanChannel or {r=255,g=255,b=255}
	end

	self.options = em.init('OptionsList',{allowInput = false})
	self.options:addOption('continue',function()
		cs = bs.load(returnData.state)
		for k,v in pairs(returnData.vars) do
			cs[k] = v
		end
		cs:init() 
	end,
	0)
	self.options:addOption('retry',function() cs = bs.load('Game') cs:init() end, 17)
	self.options:setSelection(1)

	self.pctGrade = ((self.maxHits - self.misses - (self.barelies*0.25)) / self.maxHits)*100
	self.lGrade,self.lGradePM = GameManager:gradeCalc(self.pctGrade)
	self.playedLevelsJson = dpf.loadJson("savedata/playedlevels.json",{})
	self.timesPlayed = 0
	self.storePctGrade = self.pctGrade
	self.storeMisses = self.misses
	self.storeBarelies = self.barelies

	--deal with savedata
	local saveName = LevelManager:getLevelSaveName(self.level)
	if self.playedLevelsJson[saveName] then
		self.timesPlayed = self.playedLevelsJson[saveName].timesPlayed
		self.timesPlayed = self.timesPlayed + 1
		if self.playedLevelsJson[saveName].pctGrade > self.pctGrade then
			self.storePctGrade = self.playedLevelsJson[saveName].pctGrade
			self.storeMisses = self.playedLevelsJson[saveName].misses
			self.storeBarelies = self.playedLevelsJson[saveName].barelies
		end
	else
		self.timesPlayed = 1
	end
	self.playedLevelsJson[saveName]={pctGrade=self.storePctGrade,misses=self.storeMisses,barelies=self.storeBarelies,timesPlayed=self.timesPlayed}
	dpf.saveJson("savedata/playedlevels.json", self.playedLevelsJson)

	self.zoomIn = 1

	self.zoomEase = flux.to(self,60,
		{
			zoomIn = 0,
		}
	):ease("outExpo"):oncomplete(function() self.options.allowInput = true end)
end)

st:setUpdate(function(self,dt)

	self.options:update()

end)


st:setBgDraw(function(self)

	love.graphics.setFont(fonts.digitalDisco)

	local circleY = project.res.cy + 18
	
	color('white')
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)

	if self.bgImage then

		love.graphics.draw(self.bgImage,project.res.cx,circleY - (circleY-project.res.cy)*self.zoomIn,0,1,1,math.floor(self.bgImage:getWidth()/2),math.floor(self.bgImage:getHeight()/2))
	end

	--results circle


	love.graphics.setLineWidth(2)

	love.graphics.setCanvas{cs.canv, stencil = true}
	love.graphics.clear(1,1,1,0)

	local circleRadius = 130 + self.zoomIn*200
	love.graphics.stencil(function()
			color()
			love.graphics.circle("fill",project.res.cx,circleY,circleRadius)
			love.graphics.circle("line",project.res.cx,circleY,circleRadius)
		end, 'replace', 1, true)


	love.graphics.setStencilTest('equal', 1)
	color()
	love.graphics.circle("fill",project.res.cx,circleY,circleRadius)

	color(1)
	love.graphics.printf(loc.get("grade"),0,75 - self.zoomIn*project.res.cy,project.res.x,"center")
	color()
	love.graphics.draw(sprites.results.grades[self.lGrade],project.res.cx-25,102 - self.zoomIn*project.res.cy)
	if self.lGradePM ~= "none" then
		love.graphics.draw(sprites.results.grades[self.lGradePM],project.res.cx + 2,101 - self.zoomIn*project.res.cy)
	end
	color(1)
	love.graphics.printf(loc.get("misses", {self.misses}),0,175 + self.zoomIn*project.res.cy,project.res.x,"center")
	love.graphics.printf(loc.get("barelies", {self.barelies}),0,192 + self.zoomIn*project.res.cy,project.res.x,"center")
	love.graphics.printf(loc.get("averageOffset", {self.offset}),0,209 + self.zoomIn*project.res.cy,project.res.x,"center")
	
	if savedata.options.accessibility.vfx ~= 'full' or savedata.options.accessibility.taps ~= 'default' or savedata.options.accessibility.sides ~= 'default' then
		color()
		love.graphics.draw(sprites.results.accessibility,project.res.cx,230 + self.zoomIn*project.res.cy,0,1,1,10)
		color(1)
	end
	self.options:draw(project.res.cx, 271 + self.zoomIn*project.res.cy)


	love.graphics.setLineWidth(2)
	love.graphics.circle("line",project.res.cx,circleY,circleRadius)
	love.graphics.setStencilTest()

	love.graphics.setCanvas(shuv.canvas)
	color()
	love.graphics.draw(self.canv)

	--metadata bar
	color()
	love.graphics.rectangle('fill',0,0,project.res.x, 33 - 35 * self.zoomIn)
	color(1)
	love.graphics.printf(self.level.metadata.songName,0,2 - 35 * self.zoomIn,project.res.x/2,"center",0,2)
	love.graphics.rectangle("fill",0,33 - 35 * self.zoomIn,project.res.x,2)

	-- modifiers, etc.

	if 	self.rateMod ~= 1 or
		savedata.options.accessibility.taps ~= 'default' or
		savedata.options.accessibility.vfx ~= 'full' or
		savedata.options.accessibility.sides ~= 'default'
	then
		
		local str = ''
		
		if self.rateMod then -- ok
			if self.rateMod ~= 1 then
				if str ~= '' then str = str .. ', ' end
				str = str .. loc.get('resultsRateDisplay', {string.format(self.rateMod, "%.1f")})
			end
		end
		if savedata.options.accessibility.taps ~= 'default' then
			if str ~= '' then str = str .. ', ' end
			if savedata.options.accessibility.taps == 'lenient' then str = str .. loc.get('resultsAccessibilityLenient') .. ' ' .. loc.get('resultsAccessibilityTaps') end
			if savedata.options.accessibility.taps == 'auto' then str = str .. loc.get('resultsAccessibilityAutomatic') .. ' ' .. loc.get('resultsAccessibilityTaps') end
		end
		if savedata.options.accessibility.sides ~= 'default' then
			if str ~= '' then str = str .. ', ' end
			if savedata.options.accessibility.sides == 'lenient' then str = str .. loc.get('resultsAccessibilityLenient') .. ' ' .. loc.get('resultsAccessibilitySides') end
			if savedata.options.accessibility.sides == 'auto' then str = str .. loc.get('resultsAccessibilityAutomatic') .. ' ' .. loc.get('resultsAccessibilitySides') end
		end
		if savedata.options.accessibility.vfx ~= 'full' then
			if str ~= '' then str = str .. ', ' end
			if savedata.options.accessibility.vfx == 'decreased' then str = str .. loc.get('resultsAccessibilityVFXLow') end
			if savedata.options.accessibility.vfx == 'none' then str = str .. loc.get('resultsAccessibilityVFXNone') end
		end
		
		local textWidth = fonts.digitalDisco:getWidth(str)
		
		local trapezoid = {
			 -2, 34 - (35 * self.zoomIn),		-- point 1
			(textWidth+30), 34 - (35 * self.zoomIn),		-- point 2
			(textWidth+10), 54 - (35 * self.zoomIn),		-- point 3
			 -2, 54 - (35 * self.zoomIn),		-- point 4
		}
		

		color()
		love.graphics.polygon('fill',trapezoid)
		color(1)
		love.graphics.polygon('line',trapezoid)
		love.graphics.print(str, 5, 36)
		
	end

end)


return st