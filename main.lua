function love.load()
	dofile = function(fname) return love.filesystem.load(fname)() end

	dt = 1

	freeze = 0

	-- set rescaling filter
	love.graphics.setDefaultFilter("nearest", "nearest")

	love.graphics.setLineStyle("rough")
	love.graphics.setLineJoin("miter")

	fonts = require('preload.fonts')

	-- font is https://tepokato.itch.io/axolotl-font

	for i, v in ipairs(fonts) do
		v:setFilter("nearest", "nearest", 0)
	end

	love.graphics.setFont(fonts.main)
	
	-- disable depreciation warnings for current stencil usage. once the stencil api is fully documented on the wiki,
	-- GO BACK AND FIX THIS!!!!!!!!!!!!!!!!!!!!!!!
	-- -dps
	love.setDeprecationOutput(false)

	-- import libraries

	--imgui
	if project.useImgui then
		print('importing imgui')
		if pcall(function() imgui = require "imgui" end) then
			imgui.canvasScale = 2
			imgui.canvas = love.graphics.newCanvas(project.res.x * imgui.canvasScale, project.res.y * imgui.canvasScale)
		else
			print('ERROR: imgui could not be loaded! Editor has been disabled.')
			project.useImgui = false
		end
	end

	-- lovebpm, syncs stuff to music
	lovebpm = require "lib.lovebpm"


	-- json handler
	json = require "lib.json" -- i would use a submodule, but the git repo has .lua in the name??????

	-- used for dumping tables to string.

	-- custom functions, snippets, etc
	helpers = require "lib.helpers"

	-- quickly load json files
	dpf = require "lib.dpf"
	dpf.patchLoveFilesystem()

	-- localization
	loc = require "lib.loc"
	loc.load("data/localization.json")


	-- manages gamestates
	bs = require "lib.basestate"

	-- baton, manages input handling
	baton = require "lib.baton.baton"

	if project.res.useShuv then
		shuv = require "lib.shuv"
		shuv.init(project)
		--shuv.hackyfix()
	end
	-- what it says on the tin
	utf8 = require("utf8")


	-- deeper, modification of deep, queue functions, now with even more queue
	deeper = require "lib.deeper.deeper"

	-- tesound, sound playback
	te = require "lib.tesound"


	-- jprof, profiling

	PROF_CAPTURE = project.doProfile

	prof = require "lib.profiling.jprof"

	prof.enabled(project.doProfile)

	if project.doProfile then
		print("profiling enabled!")
	end

	-- lovebird, debugging console
	if (not project.release) then
		lovebird = require "lib.lovebird.lovebird"
	else
		lovebird = require "lib.lovebirdstripped"
	end

	-- inspect - dumps vars for debugging
	inspectVar = require "lib.inspect"

	-- entity manager
	em = require "lib.entityman"

	-- spritesheet manager
	ez = require "lib.ezanim_rewrite"

	-- tween manager
	flux = require "lib.flux.flux"

	rw = require "lib.ricewine"

	--mouse code
	mouse = require "lib.mouse"
	mouse:update()


	class = require "lib.middleclass.middleclass"

	Gamestate = class('Gamestate')

	function Gamestate:initialize(name)
		self.name = name or 'newstate'
		self.updateFunc = function() end
		self.bgDrawFunc = function() end
		self.fgDrawFunc = function() end
	end

	function Gamestate:setInit(initFunc)
		self.initFunc = initFunc
	end

	function Gamestate:setUpdate(updateFunc)
		self.updateFunc = updateFunc
	end

	function Gamestate:setBgDraw(drawFunc)
		self.bgDrawFunc = drawFunc
	end

	function Gamestate:setFgDraw(drawFunc)
		self.fgDrawFunc = drawFunc
	end

	function Gamestate:init(...)
		self:initFunc(...)
	end

	function Gamestate:update(dt)
		if project.useImgui then
			if not imgui.GetWantCaptureKeyboard() then
				maininput:update()
			end
			if not imgui.GetWantCaptureMouse() then
				mouse:update()
			end
		else
			maininput:update()
			mouse:update()
		end
		lovebird.update()

		prof.push("gamestate update")
		self:updateFunc(dt)
		prof.pop("gamestate update")

		--[[
    prof.push("ricewine update")
    rw:update()
    prof.pop("ricewine update")
    ]] --
		prof.push("flux update")
		flux.update(dt)
		prof.pop("flux update")

		prof.push("entityman update")
		em.update(dt)
		prof.pop("entityman update")

		mouse:cleanup()

		te.cleanup()
	end

	function Gamestate:draw()
		if project.res.useShuv then
			shuv.start()
		end

		prof.push("bg draw")
		self:bgDrawFunc()
		prof.pop("bg draw")

		if not self.holdEntityDraw then
			prof.push("entityman draw")
			em.draw()
			prof.pop("entityman draw")
		end

		prof.push("fg draw")
		self:fgDrawFunc()
		prof.pop("fg draw")

		love.graphics.setColor(1, 1, 1, 1)

		if project.res.useShuv then
			shuv.finish()
		end
	end

	Entity = class('Entity')


	function Entity:initialize(params)
		params = params or {}
		self.layer = self.layer or 0
		self.upLayer = self.upLayer or 0
		self.delete = false

		for k, v in pairs(params) do
			self[k] = v
		end
	end

	function Entity:update(dt)
	end

	function Entity:draw(dt)
	end

	love.window.setTitle(project.name)
	paused = false

	--load sprites

	sprites = require('preload.sprites')

	-- make ezanim templates
	animations = require('preload.animations')


	-- make quads

	quads = require('preload.quads')


	-- load shaderss

	-- before loading shaders, check if the game can even run
	if not love.graphics.getSupported().glsl3 then
		love.window.showMessageBox('Beatblock could not be launched.', 'The game could not be launched because your system does not support OpenGL 3.\nYou may be able to resolve this by upgrading your graphics drivers, or by running the game on a more modern system.', 'error')
		love.event.quit()
	end
	shaders = require('preload.shaders')

	--colors
	colors = require('preload.colors')
	--sounds
	sounds = require('preload.sounds')


	function color(c)
		c = c or 'white'
		love.graphics.setColor(colors[c])
	end

	--outline helpers
	outlineCanvas = love.graphics.newCanvas(project.res.x, project.res.y)
	outlineCanvas2 = love.graphics.newCanvas(project.res.x, project.res.y)
	function outline(func, col)
		if col then
			local oldCanvas = love.graphics.getCanvas()
			local usingCanvas = outlineCanvas
			if oldCanvas == outlineCanvas then
				usingCanvas = outlineCanvas2
			end --silly little trick!
			
			love.graphics.setCanvas(usingCanvas)
				
			love.graphics.clear(0, 0, 0, 0)

			func()

			love.graphics.setCanvas(oldCanvas)

			shaders.outline:send('gameWidth', project.res.x)
			shaders.outline:send('gameHeight', project.res.y)
			shaders.outline:send('c', col)
			love.graphics.setShader(shaders.outline)
			color()
			love.graphics.draw(usingCanvas)
			love.graphics.setShader()
		else
			func()
		end
	end

	print("setting up controls")



	-- load savefile
	local defaultSave = dpf.loadJson(project.defaultSaveLoc)

	if project.noSaves then
		savedata = defaultSave
	else
		savedata = dpf.loadJson(project.saveLoc, defaultSave)
	end

	--TODO FOR POST DEMO: rewrite entire save system.

	local function checkTables(saveTable, defaultTable)
		for k, v in pairs(defaultTable) do
			if saveTable[k] == nil then
				saveTable[k] = defaultTable[k]
			elseif type(saveTable[k]) == 'table' then
				--simple check if not array
				if saveTable[k][1] == nil and saveTable[k] ~= {} then
					checkTables(saveTable[k], defaultTable[k])
				end
			end
		end
	end

	checkTables(savedata, defaultSave)


	-- baton moved after save file reading as the controls are in the save file
	
	updateControls()


	sdfunc = {}
	function sdfunc.save()
		dpf.saveJson(project.saveLoc, savedata)
	end

	function sdfunc.updateVol()
		te.volume('sfx', savedata.options.audio.sfxvolume / 10)
		te.volume('music', savedata.options.audio.musicvolume / 10)
	end

	function sdfunc.updateWindow()
		shuv.windowed_scale = savedata.options.graphics.windowScale
		--shuv.fullscreen = savedata.options.graphics.fullscreen
		shuv.displayMode = savedata.options.graphics.displayMode
		shuv.update = true
		shuv.check()
	end

	sdfunc.updateVol()
	sdfunc.save()
	sdfunc.updateWindow()
	
	
	loc.setLang(savedata.options.language)

	entities = {}
	-- load entities
	dofile('preload/entities.lua')

	-- load states

	dofile('preload/states.lua')


	-- load levels

	returnData = { state = 'SongSelect', vars = {} }

	toswap = nil
	newswap = false

	cs = bs.load(project.initState)
	cs:init()

	mouse:cleanup()
end

function love.update(d)
	prof.push("frame")

	if project.frameAdvance then
		maininput:update()
		lovebird.update()
	end
	if (not project.frameAdvance) or maininput:pressed("k1") or maininput:down("k2") then
		debugPrint = true

		if project.res.useShuv then
			shuv.check()
		end
		if not project.acDelt then
			dt = 1
		else
			dt = d * 60
		end
		if dt >= 6 then
			dt = 6
		end

		if freeze <= 0 then
			cs:update(dt)
		else
			freeze = freeze - dt
		end
	end
end

function love.draw()
	if project.useImgui then
		imgui.NewFrame()
	end

	cs:draw()
	debugPrint = false
	mouse:draw()
	prof.pop("frame")
	if project.useImgui then
		imgui.End()
		love.graphics.setCanvas(imgui.canvas)
		love.graphics.clear()
		imgui.Render()
		love.graphics.setCanvas()
		love.graphics.draw(imgui.canvas, 0, 0, 0, shuv.scale / imgui.canvasScale)
	end
end

---IMGUI STUFF
function love.textinput(t)
	if project.useImgui then
		imgui.TextInput(t)
		if not imgui.GetWantCaptureKeyboard() then
			tinput = t
		end
	else
		tinput = t
	end
end

function love.mousemoved(x, y, dx, dy)
	if project.useImgui then
		imgui.MouseMoved(x / (shuv.scale / imgui.canvasScale), y / (shuv.scale / imgui.canvasScale))
	end

	if mouse.circleSnap then
		mouse.dx = mouse.dx + dx
		mouse.dy = mouse.dy + dy
	else
		mouse.dx, mouse.dy = 0, 0
	end

	mouse.moved = true
end

function love.wheelmoved(x, y)
	if (not project.useImgui) or (not imgui.GetWantCaptureMouse()) then
		mouse.sx, mouse.sy = x, y
	end
	if project.useImgui then
		imgui.WheelMoved(y)
	end
end

function love.keypressed(key)
	if project.useImgui then
		imgui.KeyPressed(key)
	end
end

function love.keyreleased(key)
	if project.useImgui then
		imgui.KeyReleased(key)
	end
end

function love.mousepressed(x, y, button)
	if project.useImgui then
		imgui.MousePressed(button)
	end
end

function love.mousereleased(x, y, button)
	if project.useImgui then
		imgui.MouseReleased(button)
	end
end


function love.quit()
	if project.doProfile then
		print('saving profile')
		prof.write("prof.mpack")
	end
	if project.useImgui then
		imgui.ShutDown()
	end
end

-- ERROR HANDLING --
-- shoutout to 0x25a0 on love2d.org for releasing crash handling code straight into public domain
-- I reused some of it but most of this is original. - Bliv
if project.release then
	function love.errhand(error_message)
		local appName = "Beatblock"
		local version = "0.2.1 Hotfix (Demo)"
		local edition = love.system.getOS()
		
		local title = loc.get('crashTitle')
		local fullError = debug.traceback(error_message or "")
		local message = loc.get('crashBody')
		local buttons = { loc.get('crashYes'), loc.get('crashNo') }
		local pressedbutton = love.window.showMessageBox(title, message, buttons)

		if pressedbutton == 2 then -- Don't save the Crash Log
			return
		end

		local issuebody = [[
	%s crashed unexpectedly. Crash Log:

	--- SYSTEM INFO ---

	OS: %s
	CPU Processors: %i
	Game Version: %s

	--- CRASH LOG ---

	%s

	--- VARIABLE DUMP ---

	cs:
	%s

	entities:
	%s

	savedata:
	%s

	]]

		local procCount = love.system.getProcessorCount()

		issuebody = string.format(issuebody, appName, edition, procCount, version, fullError, inspectVar(cs),
			inspectVar(entities), inspectVar(savedata))

		love.filesystem.createDirectory("crashreports")
		local filename = "crashlog-" .. os.time() .. ".txt"
		love.filesystem.write("/crashreports/" .. filename, issuebody)

		love.window.showMessageBox(loc.get('crashSavedTitle'),
			loc.get('crashSavedBody',{love.filesystem.getRealDirectory("crashreports") .. "/crashreports/" .. filename})
		)
		love.system.openURL("file://" .. love.filesystem.getRealDirectory("crashreports") .. '/crashreports/')
	end
end

function love.directorydropped(path)
	--this can just be passed off to states tbh
	if cs.directorydropped then
		cs:directorydropped(path)
	end

end

function love.filedropped(file)
	--same as above
	if cs.filedropped then
		cs:filedropped(file)
	end
end

function updateControls()
	if maininput then
		maininput = nil -- destroy input controller so we can recreate it
	end
	
	controltable = {	-- moved out of the projects folder since these keys are static
		ctrl = {"key:lctrl", "key:rctrl"},
		alt = {"key:lalt", "key:ralt"},
		shift = {"key:lshift", "key:rshift"},
		delete = {"key:delete"},
		
		backspace = {"key:backspace"},
		plus = {"key:+", "key:="},
		minus = {"key:-"},
		leftbracket = {"key:["},
		rightbracket = {"key:]"},
		comma = {"key:,"},
		period = {"key:."},
		slash = {"key:/"},
		s = {"key:s"},
		x = {"key:x"},
		a = {"key:a"},
		c = {"key:c"},
		v = {"key:v"},
		g = {"key:g"},
		e = {"key:e"},
		p = {"key:p"},
		r = {"key:r"},
		i = {"key:i"},
		k1 = {"key:1"},
		k2 = {"key:2"},
		k3 = {"key:3"},
		k4 = {"key:4"},
		k5 = {"key:5"},
		k6 = {"key:6"},
		k7 = {"key:7"},
		k8 = {"key:8"},
		f4 = {"key:f4"},
		f5 = {"key:f5"},
		mouse1 = {"mouse:1"},
		mouse2 = {"mouse:2"},
		mouse3 = {"mouse:3"},
	  toggle_fullscreen = {"key:f11"}
	}
	
	-- turns out putting the values in defaultsave.json means that if they're empty, they get overriden on launch.
	-- It's messy and I don't like it, but I'm going to just have to manually check & set the binds here, instead.

	if not savedata.bindingsVersion or savedata.bindingsVersion == 1 then
		print("bindings version not found! recreating all bindings.")
		savedata.options.bindings = {
				keyboardGameplay = {
				tap1 = {"z", "space",  "mouse:1"},
				tap2 = {"x", "lshift", "mouse:2"},
				pause = {"p", "escape"},
				restart = {}
				},
				keyboardMenu = {
				select = {"return", "z", "space"},
				back = {"escape"},
				menu_up = {"up"},
				menu_left = {"left"},
				menu_right = {"right"},
				menu_down = {"down"}
				},
				keyboardEditor = {
				play = {"p"},
				move_up = {"up"},
				move_left = {"left"},
				move_right = {"right"},
				move_down = {"down"},
				modifier = {"lshift", "rshift"},
				save = {"s"},
				delete = {"delete", "backspace"}
				},
				controllerBinds = {
				select = {"a", "start"},
				back = {"b", "back"},
				menu_up = {"dpup"},
				menu_left = {"dpleft"},
				menu_right = {"dpright"},
				menu_down = {"dpdown"},
				tap1 = {"a"},
				tap2 = {"x"},
				pause = {"start"},
				restart = {}
				}
				}

		savedata.bindingsVersion = 2
			end

	if savedata.bindingsVersion == 2 or savedata.options.bindings.keyboardGameplay.tap or savedata.options.bindings.controllerBinds.tap then
		savedata.options.bindings.keyboardGameplay['tap'] = nil
		savedata.options.bindings.controllerBinds['tap'] = nil
		savedata.options.bindings.keyboardGameplay['tap1'] = {"z", "space",  "mouse:1"}
		savedata.options.bindings.keyboardGameplay['tap2'] = {"x", "lshift", "mouse:2"}
		savedata.options.bindings.controllerBinds['tap1'] = {"a"}
		savedata.options.bindings.controllerBinds['tap2'] = {"x"}
		savedata.bindingsVersion = 3
	end

	local keybinds = savedata.options.bindings
	
	for l,w in pairs(keybinds) do
		-- Check if keyboard binds or controller binds

		for k,v in pairs(keybinds[l]) do
				--if v[1] == nil then
					-- print(k .. 'has a nil value!! skipping')
			--else
			if #v == 0 then
				if not controltable[k] then
					controltable[k] = v
				end
			else
			for i = 1, #v do
				print(k)
				if string.sub(v[i], 1, 3) ~= 'key' and string.sub(v[i], 1, 6) ~= 'button' and string.sub(v[i], 1, 5) ~= 'mouse' and string.sub(v[i], 1, 4) ~= 'axis' then
					if string.sub(l, 1, 8) == 'keyboard' then
						v[i] = 'key:' .. v[i]
					else
						v[i] = 'button:' .. v[i]
					end
				end

				if not controltable[k] then
					controltable[k] = v
				else
					local combined_table = {}
					for _, value in ipairs(controltable[k]) do
						table.insert(combined_table, value)
					end
					for _, value in ipairs(v) do
						table.insert(combined_table, value)
					end
					controltable[k] = combined_table
				end
			end
			end
		end
end
	
--	for k,v in pairs(keybinds) do controltable[k] = v end -- merge savedata table and static control tables
	
	controltable['accept'] = controltable['select'] -- two different words for the same thing
	--controltable['tap1'] = controltable['tap']
	--controltable['tap2'] = controltable['tap']

	-- Hardcode mouse1 being able to be used for taps again until this can be made a configurable.
	--[[if controltable['tap'] then
		table.insert(controltable['tap'], 'mouse:1')
	else
		controltable['tap'] = {'mouse:1'}
	end]]

	-- Adds joystick controls back to the game menu.
	if controltable['menu_up'] then
		table.insert(controltable['menu_up'], 'axis:lefty-')
	else
		controltable['menu_up'] = {'axis:lefty-'}
	end

	if controltable['menu_down'] then
		table.insert(controltable['menu_down'], 'axis:lefty+')
	else
		controltable['menu_down'] = {'axis:lefty+'}
	end

	if controltable['menu_left'] then
		table.insert(controltable['menu_left'], 'axis:leftx-')
	else
		controltable['menu_left'] = {'axis:leftx-'}
	end

	if controltable['menu_right'] then
		table.insert(controltable['menu_right'], 'axis:leftx+')
	else
		controltable['menu_right'] = {'axis:leftx+'}
	end

	maininput = baton.new {
		controls = controltable,
		pairs = {
			udlr = { "menu_up", "menu_down", "menu_left", "menu_right" }
		},
		joystick = love.joystick.getJoysticks()[1],
	}
	
end
