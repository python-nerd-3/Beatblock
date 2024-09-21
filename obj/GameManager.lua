GameManager = class('GameManager',Entity)

Event = {}
Event.onLoad = {}
Event.onOffset = {}
Event.onBeat = {}
Event.info = {}

Event.editorDraw = {}
Event.editorProperties = {}

Event.hitCount = {}

Event.shouldEditorDraw = {}

Event.enum = {}
Event.enum.ease = {
	'linear',
	'inSine', 'outSine', 'inOutSine',
	'inQuad', 'outQuad', 'inOutQuad', 
	'inCubic', 'outCubic', 'inOutCubic',
	'inQuart', 'outQuart', 'inOutQuart',
	'inQuint', 'outQuint', 'inOutQuint',
	'inExpo', 'outExpo', 'inOutExpo',
	'inCirc', 'outCirc', 'inOutCirc',
	'inElastic', 'outElastic', 'inOutElastic',
	'inBack', 'outBack', 'inOutBack'
}

Event.enum.layer = {
	'bg',
	'fg',
	'ontop'
}

function Event.property(event,propertyType, propertyName, tooltip, properties)
	properties = properties or {}
	local enabled = true
	
	if properties.optional then
		enabled = imgui.Checkbox('##checkbox'..propertyName,(event[propertyName] ~= nil))
		imgui.SameLine()
		
		if enabled then
			if event[propertyName] == nil then
				event[propertyName] = properties.default
			end
		else
			event[propertyName] = nil
		end
	else
		if event[propertyName] == nil then
			event[propertyName] = properties.default
		end
	end
	
	if enabled then
		if propertyType == 'decimal' then
			imgui.PushItemWidth(100)
			event[propertyName] = imgui.InputFloat(propertyName, event[propertyName], properties.step or 0.01, properties.stepSpeed or 1, properties.decimalSize or 3)
			imgui.PopItemWidth()
		end
		if propertyType == 'int' then
			imgui.PushItemWidth(100)
			event[propertyName] = imgui.InputInt(propertyName, event[propertyName])
			imgui.PopItemWidth()
		end
		if propertyType == 'string' then
			imgui.PushItemWidth(100)
			event[propertyName] = imgui.InputText(propertyName, event[propertyName],9999)
			imgui.PopItemWidth()
		end
		if propertyType == 'bool' then
			imgui.PushItemWidth(100)
			event[propertyName] = imgui.Checkbox(propertyName, event[propertyName])
			imgui.PopItemWidth()
		end
		if propertyType == 'ease' then
			error('UH OH! YOU FORGOT THAT EASE PROPERTYTYPE DOESNT EXIST!!!!!!!!!! USE AN ENUM!!!!')
		end
		if propertyType == 'enum' then
			local comboSelection = 0
			for i,v in ipairs(Event.enum[properties.enum]) do
				if v == event[propertyName] then
					comboSelection = i
				end
			end
			
			imgui.PushItemWidth(100)
			comboSelection = imgui.Combo(propertyName, comboSelection, Event.enum[properties.enum], #Event.enum[properties.enum]);
			event[propertyName] = Event.enum[properties.enum][comboSelection]
			imgui.PopItemWidth()
		end
		if propertyType == 'colorIndex' then
			imgui.PushItemWidth(100)
			local firstValue = 0
			if properties.noColor then
				firstValue = -1
			end
			event[propertyName] = imgui.SliderInt(propertyName, event[propertyName], firstValue, 7);
			imgui.PopItemWidth()
		end
		
		--handle min/max
		if propertyType == 'int' or propertyType ==  'decimal' then
			if properties.min then
				event[propertyName] = math.max(event[propertyName], properties.min)
			end
			if properties.max then
				event[propertyName] = math.min(event[propertyName], properties.max)
			end
		end
	else
		imgui.Text(propertyName)
	end
	
	
	if properties.default then
		tooltip = tooltip .. '\nDefault value: ' .. tostring(properties.default)
	end
	
	helpers.imguiHelpMarker(tooltip)
end


local eList = {}

local function findFiles(dir)
	local files = love.filesystem.getDirectoryItems(dir)
	for i,v in ipairs(files) do
		if v ~= '_TEMPLATE.lua' then
			local path = dir..'/'..v
			local info = love.filesystem.getInfo(path)
			if info.type == 'file' then
				table.insert(eList,path)
			elseif info.type == 'directory' then
				findFiles(path)
			end
		end
	end
end

findFiles('levelformat/events')

for i,v in ipairs(eList) do
	local info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount, shouldEditorDraw = dofile(v)
	local eType = ''
	if onLoad then
		Event.onLoad[info.event] = onLoad
		eType = eType .. ' onLoad'
	end
	if onOffset then
		Event.onOffset[info.event] = onOffset
		eType = eType .. ' onOffset'
	end
	if onBeat then
		Event.onBeat[info.event] = onBeat
		eType = eType .. ' onBeat'
	end
	
	Event.editorDraw[info.event] = editorDraw
	Event.editorProperties[info.event] = editorProperties
	
	Event.hitCount[info.event] = hitCount
  
  if shouldEditorDraw then 
    Event.shouldEditorDraw[info.event] = shouldEditorDraw
  else
    Event.shouldEditorDraw[info.event] = function(event, beat, lastBeat) 
      return event.time >= beat and event.time <= lastBeat
    end
	end
  
	Event.info[info.event] = info
	print('loaded event "'..info.name..'" ('..info.event..eType..')')
end

function GameManager:initialize(params)
	
	self.skipRender = true
	self.skipUpdate = true
  self.layer = 1
  self.upLayer = -9999
  self.x=0
  self.y=0
  self.songFinished = false
	
  Entity.initialize(self,params)
	
	cs.p = em.init('Player',{x=project.res.cx,y=project.res.cy})
	
	self.lastFrame = love.graphics.newCanvas(project.res.x,project.res.y)
end

 
function GameManager:resetLevel()
	pq = ""
  cs.offset = cs.level.properties.offset
	cs.songOffset = 0
  cs.startBeat = cs.startBeat or project.startBeat or 0 
  cs.cBeat = 0-cs.offset +cs.startBeat
  cs.autoplay = false
  cs.pt = 0
  cs.bg = love.graphics.newImage("assets/bgs/nothing.png")  
	cs.bgColor = 'white'
  cs.misses= 0
  cs.hits = 0
  cs.combo = 0
  cs.maxHits = 0
	cs.barelies = 0
	cs.outline = nil
	cs.p:initialize({x=project.res.cx,y=project.res.cy})
	cs.p:update(0)
	
	cs.noteRadius = 9
	
	cs.eventQueue = {}
	
	cs.timingInfo = {
		initial = {},
		timingPoints = {}
	}
	
	rw:stopAll()
	
	shuv.resetPal()
	
	cs.taps = {}
	cs.tapTiming = {}
	
	cs.mineHits = {}
	
	cs.scrollSpeed = 1
	cs.extraHoldLeniency = 0
	
  cs.vfx = {}
	cs.vfx.time = 0
	
  cs.vfx.hom = false
	
	cs.vfx.noteXScale = 1
	cs.vfx.noteYScale = 1
	cs.vfx.noteXSkew = 0
	cs.vfx.noteYSkew = 0
	
	cs.vfx.extraTapWidth = 2
	cs.vfx.extraTapWidthPulse = 3
	
	cs.vfx.tapPulsePeriod = 1
	cs.vfx.tapPulseStrength = 1.5
	cs.vfx.tapWidthPulse = 3
	
	cs.vfx.holdSegmentLimit = 0
	
	cs.vfx.angleTwist = {offset = 0, distance = 8, ease = 'linear'}
	
  cs.vfx.bgNoise_OLD = {enable=false,image=nil,r=1,g=1,b=1,a=1}
	
	cs.vfx.bgNoise = 0
	cs.vfx.bgNoiseColor = 0
	
	cs.vfx.ignoreNoiseCorrection = false
	
	cs.vfx.hglitch = {strength = 0, resolution = 3}
	cs.vfx.vglitch = {strength = 0, resolution = 3}
	
	cs.vfx.hwaves = {strength = 0, period = 16, offset = 0, offsetDelta = 0,flip = false, flipMult = 1}
	cs.vfx.vwaves = {strength = 0, period = 16, offset = 0, offsetDelta = 0,flip = false, flipMult = 1}
	
	cs.vfx.pixelate = 1
	
	cs.vfx.effectCanvas = love.graphics.newCanvas(project.res.x,project.res.y)
	
	cs.vfx.objects = {} --things from initObject go here
	
	cs.vfx.deco = {}
	cs.vfx.decoSprites = {}
	cs.vfx.decoTemplates = {}
	
	cs.vfx.notesFollowPlayer = true
	
	cs.vfx.uiColor = 1
	
	cs.vfx.drawCombo = true
	cs.vfx.drawAccuracy = true
	cs.vfx.drawSongTitle = true
	cs.vfx.drawDifficulty = true
	cs.vfx.drawUI = true			-- drawUI supercedes all other checks
	
	cs.vfx.comboX = 0				-- we might want to move these during some levels (eg. Tutorial)
	cs.vfx.comboY = 0
	cs.vfx.accuracyX = 0
	cs.vfx.accuracyY = 0
	cs.vfx.songNameX = 0
	cs.vfx.songNameY = 0
	cs.vfx.difficultyX = 0
	cs.vfx.difficultyY = 0
	cs.vfx.glitchUIElements = 0
	
	cs.vfx.accuracyPlusX = 0		-- some levels (eg. Tutorial) need extra movement if the bigger accuracy is on
	cs.vfx.accuracyPlusY = 0
	
	cs.vfx.canvPos = {
		x = project.res.cx,
		y = project.res.cy,
		r = 0,
		sx = 1,
		sy = 1,
		ox = project.res.cx,
		oy = project.res.cy,
		kx = 0,
		ky = 0
	}
	cs.vfx.homCanvPos = {
		x = project.res.cx,
		y = project.res.cy,
		r = 0,
		sx = 1,
		sy = 1,
		ox = project.res.cx,
		oy = project.res.cy,
		kx = 0,
		ky = 0
	}
	
  cs.lastSigBeat = math.floor(cs.cBeat)
	
	if cs.editMode then return end
	--run events, if not in editor
	
	
	cs.playEvents = {}
	local loadBeatQueue = {}
	
	for i,v in ipairs(cs.level.events) do
		if cs.level.properties.loadBeat and cs.cBeat < 0 and v.time <= cs.level.properties.loadBeat then
			local loadEvent = helpers.copy(v)
			loadEvent.time = cs.cBeat
			table.insert(loadBeatQueue,loadEvent)
		else
			table.insert(cs.playEvents,helpers.copy(v))
		end
	end
	
	table.sort(loadBeatQueue,function(k1, k2)
		if k1.time ~= k2.time then
			return k1.time < k2.time
		end
		local o1 = k1.order or 0
		local o2 = k2.order or 0
		return o1 < o2
	end)
	
	for i,v in ipairs(loadBeatQueue) do
		if savedata.options.accessibility.vfx ~= 'none' or Event.info[v.type].allowInNoVFX or cs.level.properties.forceVFX then 
			if Event.onLoad[v.type] then
				Event.onLoad[v.type](v)
			end
			if Event.onOffset[v.type] then
				Event.onOffset[v.type](v)
			end
			if Event.onBeat[v.type] then
				Event.onBeat[v.type](v)
			end
		end
	end
	
	
	local mineBeats = {}
	local mineHits = 0
  for i,v in ipairs(cs.playEvents) do
		if v.type == 'mine' then --special cases for mines
			if not mineBeats[v.time] then
				mineBeats[v.time] = true
				mineHits = mineHits + 1
			end
		elseif v.type == 'mineHold' then
			if not mineBeats[v.time + v.duration] then
				mineBeats[v.time + v.duration] = true
				mineHits = mineHits + 1
			end
		else
			if Event.hitCount[v.type] then
				cs.maxHits = cs.maxHits + Event.hitCount[v.type](v)
			end
		end
  end
	cs.maxHits = cs.maxHits + mineHits
	
  cs.beatsounds = true
  for i,v in ipairs(cs.playEvents) do
    v.play_onLoad = nil
		v.play_onOffset = nil
		v.play_onBeat = nil
  end
	
	cs.tags = {}
	--tag pass
	
	for i,v in ipairs(cs.playEvents) do
		if v.type == 'tag' then
			self:checkEvent(v,'onLoad')
			--[[
			if (not v.play_onLoad) then
				Event.onLoad[v.type](v)
				v.play_onLoad = true
			end
			]]--
		end
	end
	self:runQueuedEvents()
	
	--onLoad pass
	print('running onLoad events...')
	local oLTotal = 0
	for i,v in ipairs(cs.playEvents) do
		--[[
		if Event.onLoad[v.type] then
			if (not v.play_onLoad) then
				Event.onLoad[v.type](v)
				v.play_onLoad = true
				oLTotal = oLTotal + 1
			end
		end
		]]--
		self:checkEvent(v,'onLoad')
	end
	self:runQueuedEvents()
	
	rw:play(cs.cBeat)
	rw:update(cs.cBeat)
	print('ran ' .. oLTotal .. ' events')
end

function GameManager:stopLevel()
	rw:stopAll()
	if cs.source ~= nil then
		cs.source:stop()
		cs.source = nil
	end
	if cs.p.transitionTween then cs.p.transitionTween:stop() end
	cs.soundData = nil

end


function GameManager:checkEvent(e,eventType)
	if Event[eventType][e.type] and (not e['play_'..eventType]) then
		

		
		if eventType == 'onLoad' then
			table.insert(cs.eventQueue,{event = e, eventType = eventType})
			return
		end
		
		if eventType == 'onBeat' and e.time <= cs.cBeat then
			table.insert(cs.eventQueue,{event = e, eventType = eventType})
			return
		end
		
		if eventType == 'onOffset' and e.time <= cs.cBeat + cs.offset then
			if e.time < cs.startBeat - cs.offset then
				e['play_onOffset'] = true
				return
			end
			table.insert(cs.eventQueue,{event = e, eventType = eventType})
			return
		end
			
	end
end

function GameManager:runQueuedEvents()
	if #cs.eventQueue == 0 then return end
	if #cs.eventQueue > 1 then
		table.sort(cs.eventQueue,function(k1, k2)
			if k1.event.time ~= k2.event.time then
				return k1.event.time < k2.event.time
			end
			local o1 = k1.event.order or 0
			local o2 = k2.event.order or 0
			return o1 < o2
		end)
	end
	for i,v in ipairs(cs.eventQueue) do
		v.event['play_'..v.eventType] = true
		if savedata.options.accessibility.vfx ~= 'none' or Event.info[v.event.type].allowInNoVFX or cs.level.properties.forceVFX then 
			--skip vfx events on no vfx mode
			Event[v.eventType][v.event.type](v.event)
		end

	end
	cs.eventQueue = {}
end

function GameManager:getBPM()
	return cs.level.bpm or 100
end

function GameManager:beatToMs(beat,bpm) --you gotta Trust me that the numbers check out here
	bpm = bpm or self:getBPM()
	return beat * (59500/bpm)
end

function GameManager:msToBeat(ms,bpm)
	bpm = bpm or self:getBPM()
	return ms / (59500/bpm) 
end


function GameManager:inTimingWindow(beat, ms)
	return math.abs(beat - cs.cBeat + self:msToBeat(savedata.options.game.inputOffset)) <= self:msToBeat(ms/2)
end

function GameManager:newTap(beat, allowRelease, timingWindow)
	for i,v in ipairs(cs.taps) do
		if v.beat == beat then
			v.allowRelease = v.allowRelease or allowRelease
			v.score = v.score + 1
			v.timingWindow = math.max(v.timingWindow, timingWindow)
			return v
		end
	end
	
	local tap = {}
	
	tap.beat = beat
	tap.allowRelease = allowRelease
	tap.timingWindow = timingWindow or 200
	
	
	tap.antiSpamWindow = 300
	
	
	if savedata.options.accessibility.taps == 'lenient' then
		tap.timingWindow = tap.timingWindow * 2
		tap.antiSpamWindow = 100
	end
	
	if cs.forceTimingWindow then
		tap.timingWindow = cs.forceTimingWindow
	end
	if cs.forceSpamWindow then
		tap.antiSpamWindow = cs.forceSpamWindow
	end
	
	tap.hit = false
	tap.delete = false
	tap.score = 1
	
	function tap.update(t,pressed,released)
		
		local msOffset = self:msToBeat(savedata.options.game.inputOffset)
		if t.hit then
			return false
		end
		
		local hitTap = false
		if savedata.options.accessibility.taps == 'auto' then
			if cs.cBeat >= t.beat then
				hitTap = true
				t.hit = true
				self:addToScore(t.score)
				table.insert(cs.tapTiming,0)
			end
		else
			if self:inTimingWindow(t.beat, t.timingWindow) then
				if pressed or (released and t.allowRelease) then
					hitTap = true
					t.hit = true
					self:addToScore(t.score)
					table.insert(cs.tapTiming,self:beatToMs(beat - cs.cBeat + msOffset))
				end
			elseif (t.beat > cs.cBeat - msOffset) and self:inTimingWindow(t.beat, t.timingWindow + t.antiSpamWindow) and pressed then
				print("SPAM DETECTED!!!!!!!!!")
				hitTap = true
				t.hit = true
				self:handleMiss(t.score)
				t.score = 0
				if cs.beatsounds then
					te.playOne(sounds.mine,"static",'sfx')
				end
				cs.p.emoTimer = 100
				cs.p.cEmotion = "miss"
				cs.p:hurtPulse()
				
			end
		end
		
		return hitTap
	
	end
	
	function tap.passedWindow(t)
		local msOffset = self:msToBeat(savedata.options.game.inputOffset)
		return (t.beat < cs.cBeat - msOffset) and (not self:inTimingWindow(t.beat, t.timingWindow))-- and (t.beat < cs.cBeat)
	end
	
	table.insert(cs.taps,tap)
	
	table.sort(cs.taps,function(a,b)
		return a.beat < b.beat
	end)
	
	return tap
	
end

function GameManager:updateTaps()
	
	local pressed, released = false, false
	pressed = pressed or maininput:pressed("tap1")
	pressed = pressed or maininput:pressed("tap2")
	
	released = released or maininput:released("tap1")
	released = released or maininput:released("tap2")
	
	local hitTap = false

	if pressed then
		print("pressed!!")
	end
	
	for i,v in ipairs(cs.taps) do
		--This assumes that all taps are in order, which should be true? hopefully?
		hitTap = v:update(pressed,released)
		if hitTap then
			break
		end
	end
	
	local toRemove = {}
	for i,v in ipairs(cs.taps) do
		if v.delete then
			
			if not v.hit then
				self:handleMiss(v.score)
			end
			
			table.insert(toRemove,v)
		end
		
	end
	
	for i,v in ipairs(toRemove) do
		for _i,_v in ipairs(cs.taps) do
			if _v == v then
				table.remove(cs.taps,_i)
			end
		end
	end
	
	if (not hitTap) and pressed then
		--punish player for hitting when there is no tap?
	end
	
end

function GameManager:handleMiss(hits,mine,beat)
	hits = hits or 1
	cs.misses = cs.misses + hits
	cs.combo = 0
	
end

function GameManager:addToScore(hits,barely,mine,beat)
	hits = hits or 1
	if (not mine) or (not cs.mineHits[beat]) then
		if mine then
			cs.mineHits[beat] = true
		end
		cs.hits = cs.hits + hits
		cs.combo = cs.combo + hits
	end
	if barely then
		cs.barelies = cs.barelies + hits
	end
end

function GameManager:gradeCalc(pct) --idk where else to put this, but it shouldn't go into helpers because its so game specific.
	local gradeMargins = {
		{100, 'f'},
		{98, 'd','minus'},
		{95, 'd'},
		{93, 'd','plus'},
		{90, 'c','minus'},
		{87, 'c',},
		{83, 'c','plus'},
		{80, 'b','minus'},
		{77, 'b'},
		{73, 'b','plus'},
		{70, 'a','minus'},
		{64, 'a',},
		{56, 'a','plus'},
		{50, 's','minus'},
		{-999,'perfect'}
		
	}
		
	for i,v in ipairs(gradeMargins) do
		if pct >= v[1] then
			return v[2], v[3] or 'none'
		end
	end
	return 'f', 'none'
end

function GameManager:getVFXAngle(original,distance)
	distance = math.max(distance,0)
	if cs.vfx.angleTwist.offset ~= 0 then
		original = helpers.interpolate(original, original + cs.vfx.angleTwist.offset, distance / cs.vfx.angleTwist.distance, cs.vfx.angleTwist.ease)
	end
	
	return original
end


function GameManager:update(dt)
	--IMPORTANT:
	--The way that this is set up will 100% be a performance bottleneck in the future.
	--But for now, it works well enough, even on stuff like Waves From Nothing (jit is amazing!)
	--If more complicated levels start chugging, this is where you will want to optimize.
	prof.push("GameManager update")

  pq = ""
  if cs.source == nil or self.songFinished then
		local bpm = self:getBPM()
    cs.cBeat = cs.cBeat + (bpm/60) * love.timer.getDelta()
  else
    cs.source:update()
    local beat = cs.source:getBeat()
    cs.cBeat = beat + cs.songOffset
    --print(b+sb)
  end

  -- read the level
	
	
  for i,v in ipairs(cs.playEvents) do -- onOffset + onBeat pass
		self:checkEvent(v,'onOffset')
		self:checkEvent(v,'onBeat')
  end
	self:runQueuedEvents()
  
	self:updateTaps()
	
	cs.p:savePaddleSize() 
	
  rw:update(cs.cBeat)
  if cs.combo >= math.floor(cs.maxHits / 4) then
    cs.p.cEmotion = "happy"
    cs.p.emoTimer = 99999
    --print("player should be happy")
  end
	
  prof.pop("GameManager update")
end


function GameManager:getColorSwap(c0,c1,c2,c3)
	local colorSwap = (c0 * 2^0) + (c1 * 2^2) + (c2 * 2^4) + (c3 * 2^6)
	return colorSwap
end

function GameManager:draw()
	prof.push("GameManager draw")
	
  color(cs.bgColor)
  if not cs.vfx.hom then
		love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
  else
		color()
		love.graphics.draw(self.lastFrame,
		cs.vfx.homCanvPos.x,cs.vfx.homCanvPos.y,
		math.rad(cs.vfx.homCanvPos.r),
		cs.vfx.homCanvPos.sx,cs.vfx.homCanvPos.sy,
		cs.vfx.homCanvPos.ox,cs.vfx.homCanvPos.oy,
		cs.vfx.homCanvPos.kx,cs.vfx.homCanvPos.ky)
	end
  
	--clear effect canvas
	love.graphics.setCanvas(cs.vfx.effectCanvas)
	love.graphics.clear()
  love.graphics.setCanvas(cs.canv)
	
  love.graphics.setBlendMode("alpha")

  if cs.vfx.bgNoise_OLD.enable then
    love.graphics.setColor(cs.vfx.bgNoise_OLD.r,cs.vfx.bgNoise_OLD.g,cs.vfx.bgNoise_OLD.b,cs.vfx.bgNoise_OLD.a)
    love.graphics.draw(cs.vfx.bgNoise_OLD.image,math.random(-2048+project.res.x,0),math.random(-2048+project.res.y,0))
  end
	
	if cs.vfx.bgNoise ~= 0 then
		if savedata.options.accessibility.vfx == 'full' then
			local timerDelta = love.timer.getDelta()
			if not cs.vfx.hom then
				timerDelta = 1/60 --if no hom is present, we shouldnt correctly calculate pixel change rate.
			end
			local correctedBgNoise = cs.vfx.bgNoise^(1 / ((1/60)/timerDelta) )
			--iterations = ((1/60)/love.timer.getDelta()) OR (love.timer.getFPS() / 60), not sure which will work better
			shaders.bgnoise:send('time', cs.vfx.time)
			if cs.vfx.ignoreNoiseCorrection then
				correctedBgNoise = cs.vfx.bgNoise
			end
			shaders.bgnoise:send('chance',correctedBgNoise)
			love.graphics.setShader(shaders.bgnoise)
		else --draw noise as solid in decreased vfx mode
			love.graphics.setShader()
		end
		color(cs.vfx.bgNoiseColor)
		love.graphics.draw(sprites.noisetexture)
		love.graphics.setShader()
		color()
	end
	
  love.graphics.draw(cs.bg)
	
	if cs.drawVideoBG then
		love.graphics.setShader(shaders.videoshader)
		love.graphics.draw(cs.videoBG)
		love.graphics.setShader()
	end

  color()
  em.draw()
	if savedata.options.graphics.hudStyle == "default" then
		color(cs.vfx.uiColor)
		if cs.combo >= 10 and cs.vfx.drawCombo then
			love.graphics.setFont(fonts.digitalDisco)
			local comboText = ''
			if cs.barelies == 0 and cs.misses == 0 then
				comboText = cs.combo..loc.get("comboPerfect")
			else
				comboText = cs.combo..loc.get("combo")
			end
			if cs.vfx.glitchUIElements > 0 then
				local text_len = string.len(comboText)
				comboText = ""
				for i = 1, text_len do
					comboText = comboText .. string.char(math.random(32, 127))
				end
			end
			
			outline(function()
				
				love.graphics.print(comboText,10,project.res.y - 20)
			end, cs.outline)
		end
		color()
	end

	for k,v in pairs(cs.vfx.deco) do
		if v.layer == 'ontop' then
			v:draw(true)
		end
	end
	
	prof.pop("GameManager draw")

end

function GameManager:drawExpandedHud()
	color(cs.vfx.uiColor)
	if savedata.options.graphics.hudStyle == "expanded" or savedata.options.graphics.hudStyle == "expandedPlus" then
		if cs.vfx.drawCombo and cs.vfx.drawUI then
			--love.graphics.setFont(fonts.main)
			--love.graphics.print(cs.hits.." / " .. (cs.misses+cs.hits),10,10)
			
			if cs.combo > 1 then
				love.graphics.setFont(fonts.digitalDisco)
				local combo_print = cs.combo
				local text_print = loc.get("comboExpanded")
				if cs.vfx.glitchUIElements > 0 then
					combo_print = tostring(math.random(100000, 999999))
					local text_len = string.len(text_print)
					text_print = ""
					for i = 1, text_len do
						text_print = text_print .. string.char(math.random(32, 127))
					end
				end
				outline(function()
					love.graphics.printf(combo_print, (project.res.x/2) - 100 + cs.vfx.comboX, 5 + cs.vfx.comboY, 100, "center", 0, 2, 2)
					love.graphics.printf(text_print, (project.res.x/2) - 50 + cs.vfx.comboX, 30 + cs.vfx.comboY, 100, "center")
				end, cs.outline)
			end
		end
		
		if cs.vfx.drawAccuracy and cs.vfx.drawUI then
			love.graphics.setFont(fonts.digitalDisco)
			color(cs.vfx.uiColor)
			local acc = 1
			if (cs.misses + cs.barelies + cs.hits) > 0 then -- important to avoid division by zero - assume 100% accuracy with no notes hit
				acc = (cs.hits + (cs.barelies/2))/(cs.misses + cs.barelies + cs.hits)
			end
			acc = acc * 50
			
			local text_print = loc.get("accuracyExpanded")
			if savedata.options.graphics.hudStyle == "expandedPlus" then
				
				if cs.barelies == 1 then
					text_print = text_print .. '\n 1' .. loc.get("accuracyBarelySingular")
				elseif cs.barelies > 1 then
					text_print = text_print .. '\n' .. cs.barelies .. loc.get("accuracyBarelyPlural")	
				end
				if cs.misses == 1 then
					text_print = text_print .. '\n 1' .. loc.get("accuracyMissSingular")
				elseif cs.misses > 1 then
					text_print = text_print .. '\n' .. cs.misses .. loc.get("accuracyMissPlural")
				end
			else
				cs.vfx.accuracyPlusX = 0
				cs.vfx.accuracyPlusY = 0
			end
			
			if cs.vfx.glitchUIElements > 1 then
				acc = math.random(0, 10000)/100
				local text_len = string.len(text_print)
				local text_print_b = ""
				
				for i = 1, text_len do
					if string.sub(text_print, i, i) ~= '\n' then
						text_print_b = text_print_b .. string.char(math.random(32, 127))
					else
						text_print_b = text_print_b .. '\n'
					end
				end
				
				text_print = text_print_b
			end
			
			outline(function()
				love.graphics.printf(string.format("%.2f%%", acc), project.res.x - 105 + cs.vfx.accuracyX + cs.vfx.accuracyPlusX, 5 + cs.vfx.accuracyY + cs.vfx.accuracyPlusY, 100, "right")
				love.graphics.setFont(fonts.main)
				love.graphics.printf(text_print, project.res.x - 105 + cs.vfx.accuracyX + cs.vfx.accuracyPlusX, 15 + cs.vfx.accuracyY + cs.vfx.accuracyPlusY, 100, "right")
				
				end, cs.outline)
			
		end
		
		if cs.vfx.drawSongTitle and cs.vfx.drawUI then
			love.graphics.setFont(fonts.digitalDisco)
			color(cs.vfx.uiColor)
			
			local text_print = cs.level.metadata.songName
			
			if cs.vfx.glitchUIElements > 2 then
				local text_len = string.len(text_print)
				text_print = ""
				for i = 1, text_len do
					text_print = text_print .. string.char(math.random(32, 127))
				end
			end
			local lineNum = 1
			if fonts["digitalDisco"]:getWidth(text_print) >= 500 then -- super long song title, enough to wrap
				lineNum = math.ceil(fonts["digitalDisco"]:getWidth(text_print)/500)
			end

			
			outline(function()
				love.graphics.printf(text_print, 5 + cs.vfx.songNameX, project.res.y - 4 - (13 * lineNum) + cs.vfx.songNameY, 500, "left")
			end, cs.outline)
		end
		
		if cs.vfx.drawDifficulty and cs.vfx.drawUI then
			love.graphics.setFont(fonts.digitalDisco)
			color(cs.vfx.uiColor)
			local str = cs.level.metadata.difficulty
			
			-- Hardcode specific numbers to be special strings
			if cs.level.metadata.difficulty == -1 then
				str = "?"
			end
			
			-- Hardcoded for the time being since we only have 1 diff slot
			if cs.level.metadata.difficulty <= 0 then -- SPECIAL difficulty
				str = loc.get("difficultySpecial") .. " " .. str
			elseif cs.level.metadata.difficulty <= 6 then -- EASY difficulty
				str = loc.get("difficultyEasy") .. " " .. str
			elseif cs.level.metadata.difficulty <= 10 then -- HARD difficulty
				str = loc.get("difficultyHard") .. " " .. str
			elseif cs.level.metadata.difficulty <= 14 then -- CHALLENGE difficulty
				str = loc.get("difficultyChallenge") .. " " .. str
			elseif cs.level.metadata.difficulty <= 9999 then -- EXPERT difficulty
				str = loc.get("difficultyExpert") .. " " .. str
			else -- Funny
				str = str
			end
			
			if cs.vfx.glitchUIElements > 3 then
				local text_len = string.len(str)
				str = ""
				for i = 1, text_len do
					str = str .. string.char(math.random(32, 127))
				end
			end
			
			outline(function()
				love.graphics.printf(str, project.res.x - 505 + cs.vfx.difficultyX, project.res.y - 17 + cs.vfx.difficultyY, 500, "right")
			end, cs.outline)
		end
	end
end

function GameManager:startOnTopShader()
	cs.vfx.time = cs.vfx.time + love.timer.getDelta()
	
	cs.vfx.hwaves.offset = cs.vfx.hwaves.offset + cs.vfx.hwaves.offsetDelta * love.timer.getDelta()
	cs.vfx.vwaves.offset = cs.vfx.vwaves.offset + cs.vfx.vwaves.offsetDelta * love.timer.getDelta()
	if cs.vfx.hwaves.flip then
		cs.vfx.hwaves.flipMult = cs.vfx.hwaves.flipMult * -1
	else
		cs.vfx.hwaves.flipMult = 1
	end
	if cs.vfx.vwaves.flip then
		cs.vfx.vwaves.flipMult = cs.vfx.vwaves.flipMult * -1
	else
		cs.vfx.vwaves.flipMult = 1
	end
	
	shaders.ontop:send('time', cs.vfx.time)
	
	shaders.ontop:send('hglitch_strength', cs.vfx.hglitch.strength)
	shaders.ontop:send('hglitch_resolution', cs.vfx.hglitch.resolution)
	
	shaders.ontop:send('vglitch_strength', cs.vfx.vglitch.strength)
	shaders.ontop:send('vglitch_resolution', cs.vfx.vglitch.resolution)
	
	shaders.ontop:send('hwaves_strength', cs.vfx.hwaves.strength*cs.vfx.hwaves.flipMult)
	shaders.ontop:send('hwaves_period', cs.vfx.hwaves.period)
	shaders.ontop:send('hwaves_offset', cs.vfx.hwaves.offset)
	
	shaders.ontop:send('vwaves_strength', cs.vfx.vwaves.strength*cs.vfx.vwaves.flipMult)
	shaders.ontop:send('vwaves_period', cs.vfx.vwaves.period)
	shaders.ontop:send('vwaves_offset', cs.vfx.vwaves.offset)
	
	shaders.ontop:send('pixelate', cs.vfx.pixelate)
	shaders.ontop:send('effectCanvas', cs.vfx.effectCanvas)
	
	if savedata.options.accessibility.vfx == 'full' then 
		love.graphics.setShader(shaders.ontop)
	else --no on top effects in decreased vfx mode
		love.graphics.setShader()
	end
end


function GameManager:drawCanv()
	love.graphics.draw(cs.canv,
		cs.vfx.canvPos.x,cs.vfx.canvPos.y,
		math.rad(cs.vfx.canvPos.r),
		cs.vfx.canvPos.sx,cs.vfx.canvPos.sy,
		cs.vfx.canvPos.ox,cs.vfx.canvPos.oy,
		cs.vfx.canvPos.kx,cs.vfx.canvPos.ky
	)
end

function GameManager:endOnTopShader()
	self.lastFrame:renderTo(function() self:drawCanv() end)
	love.graphics.setShader()
end


return GameManager