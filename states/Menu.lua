local st = Gamestate:new('Menu')

st:setInit(function(self)
	entities = {}

	shuv.resetPal()
	
	self.panEase = nil
	self.x = 1
	
	self.mainMenu = em.init('OptionsList',{allowInput = true})
	self.mainMenu:addOption('playdemolevels',function()
		cs = bs.load('SongSelect')
		self.menuMusicManager:clearOnBeatHooks()
		cs.menuMusicManager = self.menuMusicManager
		cs.topDirectory = 'levels/Demo/'
		cs.allowEditor = false
		cs:init()
	end, 0)
	self.mainMenu:addOption('customs',function()
		if not love.filesystem.getInfo('Custom Levels','directory') then
			love.filesystem.createDirectory('Custom Levels')
		end
		cs = bs.load('SongSelect')
		self.menuMusicManager:clearOnBeatHooks()
		cs.menuMusicManager = self.menuMusicManager
		cs.topDirectory = 'Custom Levels/'
		cs.allowEditor = true
		cs:init()
	end, 17)
	self.mainMenu:addOption('settings',function()
		
		self.mainMenu.allowInput = false
		self.optionsMenu.allowInput = true
		self.panEase = flux.to(self,60,{x = -1}):ease('outExpo')
		
	end, 34)
	self.mainMenu:addOption('credits',function()
			cs = bs.load('Credits')
			self.menuMusicManager:stop()
			--cs.menuMusicManager = self.menuMusicManager
			--cs.topDirectory = 'levels/'
			cs:init()
		end, 17*3)

	self.mainMenu:addOption('exitgame',function()
		love.event.quit()
	end, 17*4)
	if not project.release then
		
		self.mainMenu:addOption('devLevelSelect',function()
			cs = bs.load('SongSelect')
			self.menuMusicManager:clearOnBeatHooks()
			cs.menuMusicManager = self.menuMusicManager
			cs.topDirectory = 'levels/'
			cs:init()
		end, 17*5)
	else
		self.mainMenu:addOption('discordLink',function()
			love.system.openURL('https://discord.gg/MAXGRYPMSw')
		end, 17*6)
		
	end

	self.mainMenu:setSelection(1)
	
	local optionsHeight = 17
	self.optionsMenu = em.init('OptionsList',{allowInput = false})
	
	self.optionsMenu:addOption('optionsLanguage','language',optionsHeight*1)
	self.optionsMenu:defineSubmenu('language')
		local langOption = self.optionsMenu:addCustom('language',optionsHeight*1,30)
		
		langOption.languages = {'en','owo'}
		langOption.languageIndex = 0
		for i,v in ipairs(langOption.languages) do
			if v == loc.lang then 
				langOption.languageIndex = i
			end
		end
		
		
		langOption.onInput = function(langSelf,x)
			langSelf.languageIndex = (langSelf.languageIndex + x - 1) % #langSelf.languages + 1
			te.play(sounds.hold,"static",'sfx',0.5)
		end
		langOption.getText = function(langSelf)
			return '[-]  ' .. loc.get('lang_'..langSelf.languages[langSelf.languageIndex]) .. '  [+]'
		end
		
		self.optionsMenu:addOption('back',function()
			local newLanguage = langOption.languages[langOption.languageIndex]
			if loc.lang == newLanguage then
				self.optionsMenu:setSubmenu('main')
			else
				savedata.options.language = newLanguage
				sdfunc.save()
				love.event.quit('restart')
			end
		end,optionsHeight*3)
	self.optionsMenu:defineSubmenu()
	self.optionsMenu:addOption('optionsAccessibility','accessibility',optionsHeight*2)
	self.optionsMenu:defineSubmenu('accessibility')
		self.optionsMenu:addEnum('optionsVFX',{
			{'full','optionsVFXFull'},
			{'decreased','optionsVFXDecreased'},
			{'none','optionsVFXNone'}
		},savedata.options.accessibility,'vfx',optionsHeight*1)
		self.optionsMenu:addEnum('optionsTaps',{
			{'default','optionsNotesDefault'},
			{'lenient','optionsNotesLenient'},
			{'auto','optionsNotesAuto'}
		},savedata.options.accessibility,'taps',optionsHeight*2)
		self.optionsMenu:addEnum('optionsSides',{
			{'default','optionsNotesDefault'},
			{'lenient','optionsNotesLenient'},
			{'auto','optionsNotesAuto'}
		},savedata.options.accessibility,'sides',optionsHeight*3)
		self.optionsMenu:addOption('back','main',optionsHeight*5)
	self.optionsMenu:defineSubmenu()
	self.optionsMenu:addOption('optionsGraphics','graphics',optionsHeight*3)
	self.optionsMenu:defineSubmenu('graphics')
		--self.optionsMenu:addBoolean({'optionsFullscreen','optionsEnabled','optionsDisabled'},savedata.options.graphics,'fullscreen',optionsHeight*1,sdfunc.updateWindow)
		self.optionsMenu:addEnum('optionsDisplayMode',{
			{'windowed','enumWindowed'},
			{'fullscreen','enumFullscreen'},
			{'borderless','enumBorderless'}
		},savedata.options.graphics,'displayMode',optionsHeight*1, sdfunc.updateWindow)
		self.optionsMenu:addNumber('optionsWindowScale',savedata.options.graphics,'windowScale',optionsHeight*2,1,{1,5},sdfunc.updateWindow)
		self.optionsMenu:addEnum('optionsHUD', {
					{'default', 'enumHUDDefault'},
					{'expanded', 'enumHUDExpanded'},
					{'expandedPlus', 'enumHUDExpandedPlus'},
					{'none', 'enumHUDNone'}
				}, savedata.options.graphics, 'hudStyle', optionsHeight*3)	
		self.optionsMenu:addOption('back','main',optionsHeight*5)
		
	self.optionsMenu:defineSubmenu()
	self.optionsMenu:addOption('optionsAudio','audio',optionsHeight*4)
	self.optionsMenu:defineSubmenu('audio')
	
		self.optionsMenu:addNumber('optionsMusicVolume',savedata.options.audio,'musicvolume',optionsHeight*1,1,{0,10},sdfunc.updateVol)
		self.optionsMenu:addNumber('optionsSfxVolume',savedata.options.audio,'sfxvolume',optionsHeight*2,1,{0,10},sdfunc.updateVol)
		self.optionsMenu:addBoolean({'optionsHitsounds','optionsEnabled','optionsDisabled'},savedata.options.audio,'hitsounds',optionsHeight*3,sdfunc.updateVol)
		self.optionsMenu:addBoolean({'optionsPlayMenuMusic','optionsEnabled','optionsDisabled'}, savedata.options.audio, 'playMenuMusic', optionsHeight*4,function()
			if savedata.options.audio.playMenuMusic then
				self.menuMusicManager:play()
			else
				self.menuMusicManager:stop()
			end
		end)
		self.optionsMenu:addOption('back','main',optionsHeight*6)
	
	self.optionsMenu:defineSubmenu()
	self.optionsMenu:addOption('optionsGameplay','gameplay',optionsHeight*5)
	self.optionsMenu:defineSubmenu('gameplay')

		self.optionsMenu:addNumber('optionsInputOffset',savedata.options.game,'inputOffset',optionsHeight*1)
		self.optionsMenu:addOption('optionsCalibrate',function()
			
			self.menuMusicManager:stop()
			cLevel = 'levels/Other/calibration/'
			returnData = {state = 'Menu', vars = {}}
			cs = bs.load('Game')
			cs:init()
			
		end,optionsHeight*2)
		
		
		self.optionsMenu:addOption('optionsMouseSettings','mouseSettings',optionsHeight*3)
		
	
		self.optionsMenu:addOption('back','main',optionsHeight*5)
	
	self.optionsMenu:defineSubmenu()
	self.optionsMenu:defineSubmenu('mouseSettings')
		self.optionsMenu:addBoolean({'optionsCircleSnap','optionsEnabled','optionsDisabled'},savedata.options.game,'circleSnap',optionsHeight*1)
		self.optionsMenu:addBoolean({'optionsForceMouseKeyboard','optionsEnabled','optionsDisabled'},savedata.options.game,'forceMouseKeyboard',optionsHeight*2)
		self.optionsMenu:addBoolean({'optionsLockToWindow','optionsEnabled','optionsDisabled'},savedata.options.game,'lockMouseToWindow',optionsHeight*3)
		self.optionsMenu:addEnum('optionsCursorMode', {
			{'default', 'enumCursorDefault'},
			{'large', 'enumCursorLarge'},
			{'invert', 'enumCursorInvert'}
		}, savedata.options.game, 'cursorMode', optionsHeight*4)
	
		self.optionsMenu:addOption('back','gameplay',optionsHeight*6)
	
		self.optionsMenu:defineSubmenu()
		self.optionsMenu:addOption('optionsKeybinds', 'keybinds', optionsHeight*6)
		self.optionsMenu:defineSubmenu('keybinds')
		self.optionsMenu:addOption('optionsKeybindsKeyboardGameplay',function()
			local ps = cs
			cs = bs.load('Keybinds')
			cs.ps = ps
			self.menuMusicManager:clearOnBeatHooks()
			cs.menuMusicManager = self.menuMusicManager
			cs.type = 'keyboardGameplay'
			cs.keybinds = savedata.options.bindings.keyboardGameplay
			cs:init()
			end, optionsHeight*1)
		self.optionsMenu:addOption('optionsKeybindsKeyboardMenu',function()
			local ps = cs
			cs = bs.load('Keybinds')
			cs.ps = ps
			self.menuMusicManager:clearOnBeatHooks()
			cs.menuMusicManager = self.menuMusicManager
			cs.type = 'keyboardMenu'
			cs.keybinds = savedata.options.bindings.keyboardMenu
			cs:init()
			end, optionsHeight*2)
		self.optionsMenu:addOption('optionsKeybindsKeyboardEditor',function()
			local ps = cs
			cs = bs.load('Keybinds')
			cs.ps = ps
			self.menuMusicManager:clearOnBeatHooks()
			cs.menuMusicManager = self.menuMusicManager
			cs.type = 'keyboardEditor'
			cs.keybinds = savedata.options.bindings.keyboardEditor
			cs:init()
			end, optionsHeight*3)
		self.optionsMenu:addOption('optionsKeybindsControllerBinds',function()
			local ps = cs
			cs = bs.load('Keybinds')
			cs.ps = ps
			self.menuMusicManager:clearOnBeatHooks()
			cs.menuMusicManager = self.menuMusicManager
			cs.type = 'controllerBinds'
			cs.keybinds = savedata.options.bindings.controllerBinds
			cs:init()
			end, optionsHeight*4)
		self.optionsMenu:addOption('back','main',optionsHeight*6)

	self.optionsMenu:defineSubmenu('main')
	
	
	
	--[[
	enumTestValue = enumTestValue or 'enumOne'
	self.optionsMenu:addEnum('optionsTestEnum',{'enumOne','enumTwo','enumThree'},_G,'enumTestValue',optionsHeight*4)
	]]--
	
	self.optionsMenu:addOption('back',function()
		sdfunc.save()
		self.mainMenu.allowInput = true
		self.optionsMenu.allowInput = false
		self.panEase = flux.to(self,60,{x = 1}):ease('outExpo')
	end,optionsHeight*8)

	
	self.optionsMenu:setSubmenu('main')
	
	--[[
	if #te.findTag('music') == 0 then
		te.playLooping('assets/music/menuloop.ogg','stream','music')
	end
	]]
	if not self.menuMusicManager then
		self.menuMusicManager = em.init('MenuMusicManager')
		self.menuMusicManager:play()
	end


	self.logoEase = nil
	self.logoZoom = 1
	
	
	self.menuMusicManager:addOnBeatHook(function(b)
		if b % 2 == 0 then
			--self.logoZoom = 1.03
		else
			self.logoZoom = 1.1
		end
		self.logoEase = flux.to(self,60,{logoZoom=1}):ease("outExpo")
	end)

end)

st:setUpdate(function(self,dt)

	self.menuMusicManager:update()
	
	local ranFunction = self.mainMenu:update()
	if not ranFunction then
		self.optionsMenu:update()
	end

end)


st:setBgDraw(function(self)

	love.graphics.setFont(fonts.digitalDisco)
	
	color()
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)

	self.mainMenu:draw(0 + self.x * project.res.cx, 200)
	self.optionsMenu:draw(project.res.x + self.x * project.res.cx, 180)
	love.graphics.printf(loc.get('optionsHint'),project.res.cx + self.x * project.res.cx, 160,project.res.x,'center')
	
	
	love.graphics.print(loc.get('twitterPlug'),project.res.cx * -1 + 10 + self.x * project.res.cx,336)
	
	color()
	love.graphics.draw(sprites.title.logo,project.res.cx,100,0,self.logoZoom, self.logoZoom,170,32)



end)


return st