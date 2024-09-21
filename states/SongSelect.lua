local st = Gamestate:new('SongSelect')

st:setInit(function(self)
	
	self.x = -1
	self.p = em.init('Player',{x=0,y=project.res.cy})
	self.p.skipRender = true
	self.p.drawScale = 1.5
	self.canv = love.graphics.newCanvas(project.res.x,project.res.y)
	
	shuv.resetPal()
	shuv.pal[2] = {r=255,g=255,b=255}
	shuv.pal[3] = {r=255,g=255,b=255}
	shuv.pal[4] = {r=255,g=255,b=255}
	shuv.pal[5] = {r=255,g=255,b=255}
	shuv.pal[6] = {r=255,g=255,b=255}
	shuv.pal[7] = {r=255,g=255,b=255}
	
	self.topDirectory = self.topDirectory or 'levels/'
	
	self.currentDirectory = self.currentDirectory or self.topDirectory
	
	if self.allowEditor == nil then self.allowEditor = true end
	
	if not project.useImgui then
		self.allowEditor = false
	end
	
	self.menuItems = {}
	
	self.subfolderSelections = self.subfolderSelections or {}
	self.selection = self.selection or 1
	self.previousSelection = nil
	self.easedSelection = 1
	
	self.songNameScroll = 0
	self.songNameScrollDelay = 30
	self.songNameSize = 126
	
	self.songBarSize = 48
	self.songBarSelectScale = 1.5
	
	self.listView = true
	
	self.listEase = nil
	self.panEase = nil
	
	self.trapezoidEnabled = false
	self.trapezoidEase = nil
	self.trapezoidWidth = 50

	self.bgCanv = love.graphics.newCanvas(project.res.x,project.res.y)
	self.bgCanv:renderTo(function() love.graphics.clear(1,1,1,1) end)
	self.bgImage = nil
	self.bgChangeTimer = 0
	self.bgNoiseTime = 0
	
	self.goingToLevel = false
	self.centerCircleWidth = 210
	
	self.inOptionsMenu = false
	
	self.rateMod = 1.0
	self.restartOn = 'none'
	self.noBarelyJudgements = false
	
	self.songOptions = em.init('OptionsList')
	
	if self.allowEditor then
		self.songOptions:addOption('play', function() st:playLevel(self.menuItems[self.selection].filename) end, 3)
		self.songOptions:addOption('edit', function() st:editLevel(self.menuItems[self.selection].filename) end, 20)
		self.songOptions:addOption('options', function() self.inOptionsMenu = true end, 34)
		self.songOptions:addOption('back', function() self.listView = true self.panEase = flux.to(self,60,{x = -1}):ease('outExpo') end, 49)
	else
		self.songOptions:addOption('play', function() st:playLevel(self.menuItems[self.selection].filename) end, 3)
		self.songOptions:addOption('options', function() self.inOptionsMenu = true end, 20)
		self.songOptions:addOption('back', function() self.listView = true self.panEase = flux.to(self,60,{x = -1}):ease('outExpo') end, 37)
	end
	
	self.innerOptionsMenu = em.init('OptionsList')
	
	-- addNumber(text,object,value,y,increment,clamp,func)
	local ySpacing = 25
	self.innerOptionsMenu:addNumber('ratemod', self, 'rateMod', 0, 0.1, {0.5, 5})
	self.innerOptionsMenu:addEnum('optionsVFX',{
		{'full','optionsVFXFull'},
		{'decreased','optionsVFXDecreased'},
		{'none','optionsVFXNone'}
	},savedata.options.accessibility,'vfx',ySpacing*1)
	self.innerOptionsMenu:addEnum('optionsTaps',{
		{'default','optionsNotesDefault'},
		{'lenient','optionsNotesLenient'},
		{'auto','optionsNotesAuto'}
	},savedata.options.accessibility,'taps',ySpacing*2)
	self.innerOptionsMenu:addEnum('optionsSides',{
		{'default','optionsNotesDefault'},
		{'lenient','optionsNotesLenient'},
		{'auto','optionsNotesAuto'}
	},savedata.options.accessibility,'sides',ySpacing*3)
	self.innerOptionsMenu:addEnum('restartOn',{
		{'none','optionsVFXNone'},		
		{'miss','optionsRestartOnMiss'},
		{'barely','optionsRestartOnBarely'}

	},self,'restartOn',ySpacing*4)
	self.innerOptionsMenu:addBoolean({'optionsNoBarelies', 'optionsEnabled', 'optionsDisabled'}, self, 'noBarelyJudgements', ySpacing * 5)
	self.innerOptionsMenu:addOption('back', function() self.inOptionsMenu = false end, ySpacing * 7)

	
	self.innerOptionsMenu:setSelection(1)
	self.playedLevelsJson = dpf.loadJson("savedata/playedlevels.json",{})
	
	self:getMenuItems()
	
	if not self.menuMusicManager then
		self.menuMusicManager = em.init('MenuMusicManager')
		self.menuMusicManager:play()
	end
	
end)

function st:getMenuItems()
	local directoryList = love.filesystem.getDirectoryItems(self.currentDirectory)
  self.menuItems = {}
	
	for i,v in ipairs(directoryList) do
		local folderInfo = love.filesystem.getInfo(self.currentDirectory .. v .. "/")
		if love.filesystem.getInfo(self.currentDirectory .. v .. "/level.json") then
			local levelMetadata = LevelManager:loadMetadata(self.currentDirectory..v..'/')
			self:newLevel(levelMetadata, self.currentDirectory..v..'/')
		elseif folderInfo and folderInfo.type == "directory" then
			self:newFolder(v)
		elseif v:match("(.+)%.redirect") then
			local filename = love.filesystem.read(self.currentDirectory..v)
			local levelMetadata = LevelManager:loadMetadata(filename)
			self:newLevel(levelMetadata, filename)
		end
	end
	
	if self.currentDirectory == 'Custom Levels/' then
		local menuItem = {}
		menuItem.isLevel = false
		menuItem.multiLine = true
		menuItem.openCustomsFolder = true
		
		menuItem.name = loc.get('openCustomsFolder')
		menuItem.artist = loc.get('putLevelsInHere')
		table.insert(self.menuItems, menuItem)
	end
	
	if self.allowEditor then
		
		local menuItem = {}
		menuItem.isLevel = false
		menuItem.editor = true
		
		menuItem.name = loc.get('createlevel')
		
		table.insert(self.menuItems, menuItem)
	end
	
	if self.currentDirectory ~= self.topDirectory then
		local menuItem = {}
		menuItem.isLevel = false
		menuItem.back = true
		
		menuItem.name = loc.get('back')
		menuItem.filename = helpers.rliid(self.currentDirectory)
		table.insert(self.menuItems, menuItem)
	else
		local menuItem = {}
		menuItem.isLevel = false
		menuItem.quitToMenu = true
		
		menuItem.name = loc.get('quitToMenu')
		table.insert(self.menuItems, menuItem)
		
	end
	
	
	if self.subfolderSelections[self.currentDirectory] then
		self.selection = self.subfolderSelections[self.currentDirectory]
	else
		self.selection = 1
		--self.subfolderSelections[self.currentDirectory] = 1
	end
	self.previousSelection = nil
	self.easedSelection = self.selection
	self:updateSelection()
	
end

function st:updateSelection()
	if self.menuItems[self.selection].isLevel and (not self.trapezoidEnabled) then
		self.trapezoidEnabled = true
		self.trapezoidEase = flux.to(self,30,{trapezoidWidth = 204}):ease('outExpo')
	end
	
	if (not self.menuItems[self.selection].isLevel) and self.trapezoidEnabled then
		self.trapezoidEnabled = false
		self.trapezoidEase = flux.to(self,30,{trapezoidWidth = 50}):ease('outExpo')
	end
	
	if self.bgImage ~= self.menuItems[self.selection].bgImage then
		self.bgChangeTimer = 60
	end
	
	self.bgImage = self.menuItems[self.selection].bgImage
	if self.bgImage then
		shuv.pal[2] = self.menuItems[self.selection].bgRed
		shuv.pal[3] = self.menuItems[self.selection].bgBlue
		shuv.pal[4] = self.menuItems[self.selection].bgGreen
		shuv.pal[5] = self.menuItems[self.selection].bgYellow 
		shuv.pal[6] = self.menuItems[self.selection].bgMagenta
		shuv.pal[7] = self.menuItems[self.selection].bgCyan
	end
	
	
	if self.menuItems[self.selection].scroll then
		self.songNameScroll = self.songNameScrollDelay * -1
	else
		self.songNameScroll = 0
	end
	
end

function st:newLevel(levelMetadata, filename)
	local menuItem = {}
	menuItem.isLevel = true
	
	if levelMetadata.metadata.songNameDisplay then
		menuItem.name = loc.try(levelMetadata.metadata.songNameDisplay)
	else
		menuItem.name = loc.try(levelMetadata.metadata.songName)
	end
	
	menuItem.artist = levelMetadata.metadata.artist
	menuItem.artistLink = levelMetadata.metadata.artistLink or ''
	menuItem.bpm = levelMetadata.metadata.bpm
	menuItem.description = loc.try(levelMetadata.metadata.description)
	menuItem.charter = levelMetadata.metadata.charter
	menuItem.difficulty = levelMetadata.metadata.difficulty or 0
	
	menuItem.filename = filename
	
	if levelMetadata.metadata.bg and love.filesystem.getInfo(menuItem.filename .. levelMetadata.metadata.bgData.image,'file') then
		menuItem.bgImage = love.graphics.newImage(menuItem.filename .. levelMetadata.metadata.bgData.image)
		menuItem.bgRed = levelMetadata.metadata.bgData.redChannel
		menuItem.bgBlue = levelMetadata.metadata.bgData.blueChannel
		menuItem.bgGreen = levelMetadata.metadata.bgData.greenChannel or {r=255,g=255,b=255}
		menuItem.bgYellow = levelMetadata.metadata.bgData.yellowChannel or {r=255,g=255,b=255}
		menuItem.bgMagenta = levelMetadata.metadata.bgData.magentaChannel or {r=255,g=255,b=255}
		menuItem.bgCyan = levelMetadata.metadata.bgData.cyanChannel or {r=255,g=255,b=255}
		print('Loaded bg image!')
	end
	
	local saveName = LevelManager:getLevelSaveName(levelMetadata)
	if self.playedLevelsJson[saveName] then
		local sn,ch = GameManager:gradeCalc(self.playedLevelsJson[saveName].pctGrade)
		menuItem.rank = sn .. ch
		menuItem.misses = self.playedLevelsJson[saveName].misses
		menuItem.barelies = self.playedLevelsJson[saveName].barelies
	else
		menuItem.rank = "none"
		menuItem.misses = 0
		menuItem.barelies = 0
	end
	
	local nameSize = fonts.digitalDisco:getWidth(menuItem.name)
	if nameSize > self.songNameSize then 
		menuItem.scroll = (nameSize - self.songNameSize) * 2
	end
	
	table.insert(self.menuItems, menuItem)
end

function st:newFolder(filename)
	local menuItem = {}
	menuItem.isLevel = false
	menuItem.name = filename
	menuItem.filename = self.currentDirectory .. filename .. '/'
	
	table.insert(self.menuItems, menuItem)
end


function st:playLevel(filename)
	self.subfolderSelections[self.currentDirectory] = self.selection
	self.menuMusicManager:stop()
	self.goingToLevel = true
	
	self.panEase = flux.to(self,60,{x = 0,trapezoidWidth = 40}):ease('outExpo')
	flux.to(self,80,{centerCircleWidth=430}):ease('inSine')
	cs.p.forceSprite = 'happy' --funny idea that i dont feel like implementing right now, what if this could be set per song?
	--"scary" songs make cranky show the miss expression?
	cs.p:growTransition(function() 
		cLevel = filename
		returnData = {state = 'SongSelect', vars = {topDirectory = self.topDirectory, currentDirectory = self.currentDirectory,
			selection = self.selection, subfolderSelections = self.subfolderSelections, allowEditor = self.allowEditor}}
		self:deletePlayer()
		
		--special case for iloveyou and inverses
		if filename == 'levels/Finished levels/ILOVEYOUvbs/' and not savedata.seenInverseTutorial then
			cs = bs.load('InverseTutorial')
			cs:init()
			return
		end
		
	
		
		cs = bs.load('Game')

		cs.noBarelyJudgements = self.noBarelyJudgements
		cs:init() 
		
		cs.rateMod = self.rateMod
		cs.restartOn = self.restartOn
		
	end)

end


st:setUpdate(function(self,dt)
	self.menuMusicManager:update()
	if self.bgChangeTimer > 0 then
		self.bgChangeTimer = self.bgChangeTimer - dt
	end
	self.bgNoiseTime = self.bgNoiseTime + love.timer.getDelta()
	
	if self.p then
		self.p.x = project.res.cx - self.x * 150
	end
	
	if self.goingToLevel then
		return
	end
	
	if self.listView then
		local moved = false
		if maininput:pressed("menu_up") then
			self.previousSelection = self.selection
			self.selection = self.selection - 1
			moved = true
		end
		if maininput:pressed("menu_down") then
			self.previousSelection = self.selection
			self.selection = self.selection + 1
			moved = true
		end
		
		if mouse.sy and mouse.sy ~= 0 then
			self.previousSelection = self.selection
			self.selection = self.selection - helpers.clamp(mouse.sy,-1,1)
			moved = true
		end
		
		local clickedOnLevel = false
		if mouse.pressed == 1 and mouse.rx >= 68 and mouse.rx <= 290 then
			local mouseYOffset = self.songBarSize * (self.songBarSelectScale - 1) * 0.5
			if mouse.ry > project.res.cy then
				mouseYOffset = mouseYOffset * -1
			end
			local clickPosition = math.floor(((mouse.ry + mouseYOffset - project.res.cy) / self.songBarSize)+0.5)
			local newSelection = helpers.clamp(self.selection + clickPosition,1,#self.menuItems)
			if clickPosition == 0 then
				clickedOnLevel = true
			elseif newSelection ~= self.selection then
				self.previousSelection = self.selection
				self.selection = newSelection
				moved = true
			end
			
		end
		
		self.selection = (self.selection - 1) % #self.menuItems + 1
		
		if moved then
			te.play(sounds.click,"static",'sfx',0.5)
			
			self.listEase = flux.to(self,30,{easedSelection=self.selection}):ease("outExpo")
			--self.easedSelection = self.selection
			self:updateSelection()
			
		end
		
		if self.menuItems[self.selection].scroll then
			self.songNameScroll = self.songNameScroll + dt * 0.5
			if self.songNameScroll >= self.menuItems[self.selection].scroll + self.songNameScrollDelay then
				self.songNameScroll = self.songNameScrollDelay * -1
			end
		end
		
		if maininput:pressed("accept") or clickedOnLevel then
			local can_navigate_to_menu = true
			if self.menuItems[self.selection].filename == 'levels/Finished levels/internal_locked_level/' then
				can_navigate_to_menu = false
			end
			if can_navigate_to_menu then
				te.play(sounds.hold,"static",'sfx',0.5)
				if self.menuItems[self.selection].isLevel then
					self.listView = false
					
					self.songOptions:setSelection(1)
					
					self.bgChangeTimer = 0
					
					self.panEase = flux.to(self,60,{x = 1}):ease('outExpo')
				elseif self.menuItems[self.selection].editor then
					self:editLevel(self.currentDirectory,true)
				elseif self.menuItems[self.selection].quitToMenu then
					self:quitToMenu()
				elseif self.menuItems[self.selection].openCustomsFolder then
					print('open customs folder')
					love.system.openURL("file://"..love.filesystem.getSaveDirectory()..'/'..'Custom Levels')
				else--folder/back
					if self.listEase then
						self.listEase:stop()
					end
					self:changeDirectory(self.menuItems[self.selection].filename)
				end
			else
				te.play(sounds.mine,"static",'sfx',0.5)
			end
		end
		
		if maininput:pressed('e') and self.menuItems[self.selection].isLevel and self.allowEditor then
			self:editLevel(self.menuItems[self.selection].filename)
		end
		
		if maininput:pressed('back') then
			if self.currentDirectory ~= self.topDirectory then
				if self.listEase then
					self.listEase:stop()
				end
				self:changeDirectory(helpers.rliid(self.currentDirectory))
			else
				self:quitToMenu()
			end
		end
	else
		if not self.inOptionsMenu then
			self.songOptions:update()

			if maininput:pressed('e') and self.allowEditor then
				st:editLevel(self.menuItems[self.selection].filename)
			end
			
			if maininput:pressed('back') then
				self.listView = true
				self.panEase = flux.to(self,60,{x = -1}):ease('outExpo')
			end
		else
			
			self.innerOptionsMenu:update()
			
			if maininput:pressed('back') then
				self.inOptionsMenu = false
			end
		end
		
		
		if self:drawSongInfo(self.menuItems[self.selection],project.res.cx - self.x * 200,true) and mouse.pressed == 1 and not self.inOptionsMenu then
			
			
			
			love.system.openURL(self.menuItems[self.selection].artistLink)
		end
		
	end
	
end)

function st:quitToMenu()
	cs = bs.load('Menu')
	self.menuMusicManager:clearOnBeatHooks()
	cs.menuMusicManager = self.menuMusicManager
	cs:init()
end


function st:editLevel(filename,newLevel)
	self.subfolderSelections[self.currentDirectory] = self.selection
	self.menuMusicManager:stop()
	cLevel = filename
	self:deletePlayer()
	
	if savedata.seenEditorWarning then
		cs = bs.load('Editor')
	else
		cs = bs.load('EditorWarning')
	end
	cs.newLevel = newLevel
	returnData = {state = 'SongSelect', vars = {topDirectory = self.topDirectory, currentDirectory = self.currentDirectory,
		selection = self.selection, subfolderSelections = self.subfolderSelections, allowEditor = self.allowEditor}}
	
	cs:init()
end


function st:deletePlayer()
  self.p.delete = true
  self.p=nil
end



function st:changeDirectory(newDirectory)
	print('Changing directory from ' .. self.currentDirectory .. ' to ' .. newDirectory)
	if self.menuItems[self.selection].back then
		self.subfolderSelections[self.currentDirectory] = 1
	else
		self.subfolderSelections[self.currentDirectory] = self.selection
	end
	self.currentDirectory = newDirectory
	self:getMenuItems()
end

function st:directorydropped(path)
	if self.topDirectory ~= 'Custom Levels/' then
		return
	end
	if love.filesystem.mount(path, "draganddrop") then
		local savedataPath = self.currentDirectory
		if love.filesystem.getInfo("draganddrop/chart.json") then
			local foldername = string.match(path, "(%a*)[%.%a*]?$")
			-- get the name of the folder with or without an extension
			savedataPath = savedataPath .. foldername
			love.filesystem.createDirectory(savedataPath)
		end
		helpers.recursiveFolderCopy(savedataPath, "draganddrop")
		love.filesystem.unmount(path)
	end
	self:getMenuItems()
end

function st:filedropped(file)
	if self.topDirectory ~= 'Custom Levels/' then
		return
	end
	local path = file:getFilename()
	if string.sub(path, -4, -1) ~= ".zip" then
		return
	end

	if love.filesystem.mount(path, "draganddrop") then
		local savedataPath = self.currentDirectory
		if love.filesystem.getInfo("draganddrop/chart.json") then
			local foldername = string.match(path, "(%a*)%.%a*$")
			-- get the name of the zip file without an extension
			savedataPath = savedataPath .. foldername
			love.filesystem.createDirectory(savedataPath)
		end
		helpers.recursiveFolderCopy(savedataPath, "draganddrop")
		love.filesystem.unmount(path)
	end
	self:getMenuItems()
end


function st:drawSongInfo(level,xBorder,dontDraw)
	love.graphics.setFont(fonts.digitalDisco)
	local xOffset = 214
	local wrapLimit = 230
	local artistY = helpers.printRect(level.name,xBorder+xOffset,0,wrapLimit,78,'left',2,dontDraw) + 6
	local artistWidth, lines = fonts.digitalDisco:getWrap(level.artist,wrapLimit)
	
	local linkX, linkY = xBorder+xOffset+artistWidth + 4, artistY+2
	local touchingLink = false
	if helpers.collide(
		{x = mouse.rx, y = mouse.ry, width = 0, height = 0},
		{x = linkX, y = linkY, width = 12, height = 12}
	) then
		touchingLink = true
	end
	if dontDraw then
		return touchingLink and level.artistLink ~= ''
	end
	
	local smallTextOffset = 2
	
	love.graphics.printf(level.artist,xBorder+xOffset,artistY,wrapLimit,'left')
	if level.artistLink ~= '' then
		
		local radius = 6
		if touchingLink then
			love.graphics.setLineWidth(2)
		else
			love.graphics.setLineWidth(1)
		end
			
		love.graphics.circle('line',math.floor(linkX + 6),math.floor(linkY + 6), radius)
		color()
		love.graphics.draw(sprites.songselect.artistlink,math.floor(linkX),math.floor(linkY))

		
	end
	color(1)
	love.graphics.setLineWidth(2)
	love.graphics.line(xBorder,artistY+17,project.res.x,artistY+17)
	
	local bpmY = artistY + 19
	love.graphics.printf(level.bpm,xBorder+xOffset,bpmY,wrapLimit,'left')
	love.graphics.line(xBorder,bpmY+17,project.res.x,bpmY+17)
	
	
	love.graphics.printf(level.description,xBorder+xOffset,bpmY+19,wrapLimit,'left')
end

function st:drawRank(level,xOffset,trapezoidHeight)
	if level.isLevel then
		if level.rank ~= 'none' then
			color()
			love.graphics.draw(sprites.songselect.grades[level.rank],xOffset+12,trapezoidHeight)
			love.graphics.setFont(fonts.main)
			color(1)
			love.graphics.printf(loc.get('misses',{level.misses})..'\n'..loc.get('barelies',{level.barelies}),xOffset-18,trapezoidHeight+36,70,'center')
		else
			color(1)
			love.graphics.print(loc.get('unplayed'), xOffset - 18, trapezoidHeight+40,0,1,1)
		end
	end
end


function st:drawBgArt(x)
	--[[
	when changing to a new BG, or changing from a bg to no bg at all, set
	self.bgChangeTimer to 60.
	Count down by DT every frame.
	If bgChangeTimer is over 0, then the BG art will be drawn with the noise filter, letting it "fade" from the previous state.
	]]
	love.graphics.setCanvas(cs.bgCanv)
	
	local bgImage = self.bgImage or sprites.noisetexture
	color()
	local noiseChance = (0.7)^(1 / ((1/60)/love.timer.getDelta()) )
	
	if self.bgChangeTimer > 0 then
		shaders.bgnoise:send('time', self.bgNoiseTime)
		shaders.bgnoise:send('chance',noiseChance)
		love.graphics.setShader(shaders.bgnoise)
	end
	
	love.graphics.draw(bgImage,x,project.res.cy,0,1,1,math.floor(bgImage:getWidth()/2),math.floor(bgImage:getHeight()/2))
	
	if self.bgChangeTimer > 0 then
		love.graphics.setShader()
	end
	
	love.graphics.setCanvas(cs.canv)
end

st:setBgDraw(function(self)
	--do all this in a canvas for easy stencil access
	--[[
	stencil layout is like this, kinda:
	0: Outermost zone, particles (if any) probably go here?
	1: The actual main content, song wheel + song info, depending on side!
	2: Cranky + per song BG
	3: Black outlines between zones
	
	00 3 111 3 222
	0 3 111 3 2222
	0 3 111 3 2222
	0 3 111 3 2222
	00 3 111 3 222
	
	]]--
  color(0)
	
	
	local xBorder = project.res.cx - self.x * 200
	
	--draw bg art before stencil stuff
	self:drawBgArt(xBorder)
	
	
	love.graphics.setLineWidth(2)
	
	love.graphics.setCanvas{cs.canv, stencil = true}
	love.graphics.clear(1,1,1,1)
	
	--1 stencil
	love.graphics.stencil(function()
		love.graphics.circle('fill',project.res.cx - self.x * 170, project.res.cy, 440)
	end, 'replace', 1, true)



	--2 stencil
	love.graphics.stencil(function()
		love.graphics.circle('fill',project.res.cx - self.x * 200, project.res.cy, self.centerCircleWidth)
	end, 'replace', 2, true)
	
	--3 stencil
	love.graphics.stencil(function()
		love.graphics.circle('line',project.res.cx - self.x * 170, project.res.cy, 440)
		love.graphics.circle('line',project.res.cx - self.x * 200, project.res.cy, self.centerCircleWidth)

	end, 'replace', 3, true)
	
	
	--0 draw
	love.graphics.setStencilTest('equal', 0)
	
	--1 draw
	love.graphics.setStencilTest('equal', 1)
  love.graphics.setFont(fonts.digitalDisco)
	
	--song list side

	local yTop = project.res.cy - ((self.easedSelection-1) * self.songBarSize) - (self.songBarSize * self.songBarSelectScale * 0.5)
	local yTotal = 0
	for i,v in ipairs(self.menuItems) do
		
		local myHeight = self.songBarSize
		
		if self.previousSelection then
			--self.previousSelection,self.selection,self.easedSelection
			local easeProgress = math.abs(self.easedSelection - self.previousSelection) / math.abs(self.selection - self.previousSelection)
			if i == self.selection then
				myHeight = self.songBarSize * (1 + easeProgress * (self.songBarSelectScale-1))
			elseif i == self.previousSelection then
				myHeight = self.songBarSize * (self.songBarSelectScale - easeProgress * (self.songBarSelectScale-1))
			end
		else
			if i == self.selection then
				myHeight = self.songBarSize * self.songBarSelectScale
			end
		end
		
		
		--local y = project.res.cy + (i - self.easedSelection) * 48
		local y = yTop + yTotal + myHeight * 0.5
		local x = math.sin( ((y - project.res.cy) / (30*math.pi)) - (math.pi * 0.5) ) * 30 - 454 + (project.res.cx - self.x * self.centerCircleWidth)
		
		yTotal = yTotal + myHeight
		
		if i == self.selection then
			love.graphics.setLineWidth(4)
		else
			love.graphics.setLineWidth(2)
		end
		
		color(1)
		love.graphics.line(0,y - myHeight * 0.5,xBorder,y - myHeight * 0.5)
		love.graphics.line(0,y + myHeight * 0.5,xBorder,y + myHeight * 0.5)
		
		
		
		--love.graphics.line(0,y + 24,xBorder,y + 24)
		
		
		--color(3)
		--love.graphics.line(0,y,project.res.x,y)
		--love.graphics.circle('fill',x,y,10)
			
		color(1)
		if v.isLevel or v.multiLine then
			--level
			local xOffset = 0 
			if i == self.selection and v.scroll then
				xOffset = helpers.clamp(self.songNameScroll, 0, v.scroll) * -1
			end
			love.graphics.print(v.name,x+10+xOffset,y-23,0,2,2)
			love.graphics.print(v.artist,x+10,y+5,0,1,1)
		elseif v.back then
			--back
			love.graphics.print(v.name,x+10,y-15,0,2,2)
		else
			--folder
			love.graphics.print(v.name,x+10,y-15,0,2,2)
		end
	end
	

	color()
	love.graphics.rectangle('fill',xBorder, 0, project.res.x, project.res.y)
	--trapezoid + song menu items

	color(1)
	local trapezoidHeight = 307
	
	local y_offset = 0
	if self.allowEditor then
		y_offset = -12
	end
	
	
	if not self.inOptionsMenu then
	if self.allowEditor then
		self.songOptions:draw(300+xBorder, trapezoidHeight - 12)
	else
		self.songOptions:draw(300+xBorder, trapezoidHeight)
	end
	

	
	love.graphics.setLineWidth(2)
	love.graphics.line(xBorder, trapezoidHeight+y_offset,project.res.x, trapezoidHeight+y_offset)
	
	else

		love.graphics.setLineWidth(2)
		love.graphics.line(xBorder, 40, project.res.x, 40)
		
		love.graphics.printf(loc.get('optionsMenuHeader'), xBorder + ((project.res.x - xBorder)/4), 7, 200, 'center', 0, 2, 2)

		local canPRank = true
		
		if (	-- other "blatantly cheating" options (autoplay?) go here
			self.rateMod < 1 or 
			savedata.options.accessibility.taps ~= 'default' or
			savedata.options.accessibility.sides ~= 'default'
		) then
			canPRank = false
		end

		if not canPRank then
			love.graphics.setFont(fonts.main)
			--love.graphics.print(loc.get('noPRankMessage'), 268, 41)
			
			love.graphics.setFont(fonts.digitalDisco)
		end

		self.innerOptionsMenu:draw(325 + xBorder, 60)
		
		
		
		
		if self.innerOptionsMenu.selection ~= #self.innerOptionsMenu.options.main then
			local descriptionString = loc.get('optionsMenuDescription' .. self.innerOptionsMenu.selection)
			love.graphics.printf(descriptionString, 180+xBorder, 300,260,'left')
		end
		--self.innerOptionsMenu.selection
	end

	
	local currentLevel = self.menuItems[self.selection]
	
	

	
	--song info side
	if currentLevel.isLevel and not self.inOptionsMenu then
		color(1)
		self:drawSongInfo(currentLevel,xBorder)
		love.graphics.setLineWidth(2)
		color(1)
		love.graphics.line(xBorder, trapezoidHeight-17+y_offset,project.res.x, trapezoidHeight-17+y_offset)
		local difficultyString = currentLevel.charter
		--[[
		if currentLevel.difficulty ~= 0 then
			difficultyString = currentLevel.difficulty .. ' - ' .. difficultyString .. 'HHHH'
		end
		]]
		love.graphics.printf(difficultyString,xBorder+170,trapezoidHeight-16+y_offset,260,'center')
	end
		
	
	
  --2 draw
	love.graphics.setStencilTest('equal', 2)
	color()
	love.graphics.draw(cs.bgCanv)
	self.p:draw()
	
	--3 draw
	love.graphics.setStencilTest('equal', 3)
	color(1)
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
	
	--on top
	love.graphics.setStencilTest('notequal',0)
	
	local trapezoidX = project.res.x + 120+ self.x*-30
	love.graphics.setLineWidth(2)

	local isDemo = true -- The demo only has one difficulty slot so override diffTable

	local diffTable = currentLevel.difficulties
	
	
	if not currentLevel.difficulties then
		diffTable = {0, currentLevel.difficulty}
	end
	
	if isDemo then
		diffTable = {currentLevel.difficulty}
	end
	
	local difficultyAmount = (#diffTable) -- TODO: implement this
	
	love.graphics.setFont(fonts.digitalDisco)
	
	if (not self.goingToLevel) and (not self.inOptionsMenu) then
		for i = difficultyAmount, 1, -1 do
			
			local difficultyHeight = 27
			local difficultyWidth = 54
			local panMult = 50
			local magic_number = (difficultyHeight)*(i-(difficultyAmount - 1))
			
			local str = diffTable[i]
			
			-- Hardcode specific numbers to be special strings
			if diffTable[i] == -1 then
				str = "?"
			end
			
			if diffTable[i] < 0 then
				str = loc.get("difficultySpecial") .. " " .. str
			elseif diffTable[i] == 0 then
				str = "----"
			elseif diffTable[i] <= 6 then
				str = loc.get("difficultyEasy") .. " " .. str
			elseif diffTable[i] <= 10 then
				str = loc.get("difficultyHard") .. " " .. str
			elseif diffTable[i] <= 14 then
				str = loc.get("difficultyChallenge") .. " " .. str
			elseif diffTable[i] <= 9999 then
				str = loc.get("difficultyExpert") .. " " .. str
			else
				-- nothing
			end
			
			difficultyWidth = 20 + fonts.main:getWidth(str)
			
			local trapezoid = {
				trapezoidX + (panMult*(self.x+1)) - self.trapezoidWidth - difficultyWidth - difficultyHeight - magic_number,	trapezoidHeight +  0 + magic_number,
				trapezoidX + (panMult*(self.x+1)) + self.trapezoidWidth,							trapezoidHeight +  0 + magic_number,

				trapezoidX + (panMult*(self.x+1)) + self.trapezoidWidth + difficultyHeight*2, 						trapezoidHeight + difficultyHeight + magic_number,
				trapezoidX + (panMult*(self.x+1)) - self.trapezoidWidth - difficultyHeight*2 - difficultyWidth - magic_number, 	trapezoidHeight + difficultyHeight + magic_number,}

			color()
			love.graphics.polygon('fill',trapezoid)
			color(1)
			love.graphics.polygon('line',trapezoid)
			

			
			
			love.graphics.print(str, trapezoid[1] + 1, trapezoid[2] + 4, 0,1,1)

		end
	end

	
	if not self.inOptionsMenu then
		trapezoid = {trapezoidX - self.trapezoidWidth, trapezoidHeight, trapezoidX + self.trapezoidWidth, trapezoidHeight,
			trapezoidX + self.trapezoidWidth + 56, trapezoidHeight+56, trapezoidX - self.trapezoidWidth - 56, trapezoidHeight+56}
		color()
		love.graphics.polygon('fill',trapezoid)
		color(1)
		love.graphics.polygon('line',trapezoid)
	end
	--[[
	if currentLevel.difficulty and currentLevel.difficulty ~= 0 then
		love.graphics.setFont(fonts.digitalDisco)
		love.graphics.print(currentLevel.difficulty,trapezoidX - self.trapezoidWidth - 36, trapezoidHeight+40,0,1,1)
	end
	]]
	
	--redraw outermost circle
	love.graphics.circle('line',project.res.cx - self.x * 170, project.res.cy, 440)
	
	if not self.inOptionsMenu then
		self:drawRank(currentLevel,trapezoidX - self.trapezoidWidth,trapezoidHeight-20)
	end
	--self:drawRank(currentLevel,trapezoidX + self.trapezoidWidth-32,trapezoidHeight)

	love.graphics.setStencilTest()
	love.graphics.setCanvas(shuv.canvas)
	color()
	love.graphics.draw(self.canv)
	


end)
--entities are drawn here
st:setFgDraw(function(self)
  
  
end)

return st