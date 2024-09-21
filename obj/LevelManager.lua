LevelManager = class('LevelManager',Entity)

local currentVersion = 12
--[[
FORMAT CHANGELOG:
- Version 0:  initial version
- Version 1:  Split chart and vfx+metadata into two separate files, chart.json and level.json
- Version 2:  Replace "beat" event type with "block". "beat" still exists as a legacy event type.
- Version 3:  all events have an "angle" parameter for editor display. "hold" event's angle1 parameter has been renamed to angle
- Version 4:  Mine holds also use angle1 - angle conversion
- Version 5:  The Big Renaming:tm:
- Version 6:  "width" event now operates in beats instead of 1/60s
- Version 7:  Artist link in level metadata
- Version 8:  Difficulty numbers. Will probably need to be reworked if we add multiple difficulties?
- Version 9:  Song select bg
- Version 10: Global order parameter for events
- version 11: Multipaddle rework
- version 12: Fix for 0 duration events
]]--
function LevelManager:initialize(params)
	
	self.skipRender = true
	self.skipUpdate = true
  self.layer = 1
  self.upLayer = -9999
  self.x=0
  self.y=0
	
  Entity.initialize(self,params)
	
end

function LevelManager:loadLevel(filename)
	filename = filename or cLevel
	
	local level = dpf.loadJson(filename .. "level.json")
	local chart = nil
	if level.properties.formatversion then
		if level.properties.formatversion >= 1 then
			chart = dpf.loadJson(cLevel .. "chart.json")
		end
	end
	
	if chart then
		for i,v in ipairs(chart) do
			table.insert(level.events,v)
		end
	end
	
	
	
	
	level, level.events = self:upgradeLevel(level,level.events,filename,true)
	
	if project.strictLoading then
		for i,v in ipairs(level.events) do
			if not Event.info[v.type] then
				error('UNKNOWN EVENT TYPE IN LEVEL: ' .. v.type .. ' AT BEAT ' .. v.time)
			end
		end
	end
	
	return level
	
end


function LevelManager:loadMetadata(filename)
	filename = filename or cLevel
	
	local level = dpf.loadJson(filename .. "level.json")
	level, level.events = self:upgradeLevel(level,level.events,filename,true)
	
	local bpms = {}
	for i,v in ipairs(level.events) do
		if v.type == 'play' or v.type == 'setBPM' then
			table.insert(bpms,v.bpm)
		end
	end
	
	if #bpms == 0 then
		level.metadata.bpm = '???'
	elseif #bpms == 1 then
		level.metadata.bpm = math.floor(bpms[1] * 1000 + 0.5) / 1000
	else
		local minBPM = bpms[1]
		local maxBPM = bpms[1]
		for i=2,#bpms do
			minBPM = math.min(bpms[i],minBPM)
			maxBPM = math.max(bpms[i],maxBPM)
		end
		minBPM = math.floor(minBPM * 1000 + 0.5)/1000
		maxBPM = math.floor(maxBPM * 1000 + 0.5)/1000
		
		level.metadata.bpm = minBPM .. '-' .. maxBPM
	end
	
	level.metadata.bpm = loc.get('bpm',{level.metadata.bpm})
	
	return level
	
end

function LevelManager:getLevelSaveName(levelMetadata)
	return levelMetadata.metadata.songName.."_"..levelMetadata.metadata.artist.."_"..levelMetadata.metadata.charter
end

function LevelManager:newLevel(filename)
	local level = {
		metadata = {
			artist = 'Artist',
			songName = 'Song name',
			charter = 'Charter',
			artistLink = '',
			description = 'Wow! It\'s a level!',
			difficulty = 0,
			bg = false,
			--[[
			bgData = {
				image = 'image.png',
				redChannel = {r=255,g=0,b=0},
				blueChannel = {r=0,g=0,b=255}
			}
			]]--
		},
		properties = {
			offset = 8,
			startBeat = 0,
			--loadBeat = -1,
			speed = 70,
			formatversion = currentVersion
		},
		events = {}
	}
	
	self:saveLevel(level,filename,true)
	cLevel = filename
	return level
end

function LevelManager:iterateEvents(events, func, filename, readOnly)
	
	local newEvents = {}
	
	local tagNames = {}
	
	
	for i,v in ipairs(events) do
		table.insert(newEvents,func(v))
		if v.type == 'tag' then
			tagNames[v.tag] = true
		end
	end
	--level.events = newEvents
	if not readOnly then
		for tagName, _ in pairs(tagNames) do
			local tagEvents = dpf.loadJson(filename .. "tags/" .. tagName ..'.json')
			local newTagEvents = {}
			for i,v in ipairs(tagEvents) do
				table.insert(newTagEvents,func(v))
				if v.type == 'tag' then
					tagNames[v.tag] = true
				end
			end
			dpf.saveJson(filename .. "tags/" .. tagName ..'.json',newTagEvents)
		end
	end
	
	return newEvents
	
end

function LevelManager:upgradeLevel(level,events,filename, readOnly)
	local saveboth = false
	--format 1
	if level.properties.formatversion == nil then
		level.properties.formatversion = 1
		saveboth = true -- this changes format significantly, so it requires a resave. for minor revisions, this is not needed.
	end
	
	--format 2
	if level.properties.formatversion < 2 then
		level.properties.formatversion = 2
		for i,v in ipairs(events) do
			if v.type == 'beat' then
				v.type = 'block'
			end
		end
	end
	
	--format 3
	if level.properties.formatversion < 3 then
		level.properties.formatversion = 3
		for i,v in ipairs(events) do
			if v.type == 'hold' then
				v.angle = v.angle1
				v.angle1 = nil
			else
				v.angle = v.angle or 0
			end
		end
	end
	
	--format 4
	if level.properties.formatversion < 4 then
		level.properties.formatversion = 4
		for i,v in ipairs(events) do
			if v.type == 'minehold' then
				v.angle = v.angle1 or v.angle
				v.angle1 = nil
			end
		end
	end
	
	
	--format 5
	if level.properties.formatversion < 5 then --TODO: generalize this for future event renamings, if there are any.
		level.properties.formatversion = 5
		
		local valueChanges = {}
		local keyChanges = {}
		do -- big ol list of changes
		--Event types
			valueChanges['bgnoise'] = 'bgNoise'
			valueChanges['videobg'] = 'videoBG'
			valueChanges['initobject'] = 'initObject'
			valueChanges['minehold'] = 'mineHold'
			valueChanges['multipulse'] = 'multiPulse'
			valueChanges['setbg'] = 'setBG'
			valueChanges['setbgcolor'] = 'setBgColor'
			valueChanges['setbpm'] = 'setBPM'
			valueChanges['setcolor'] = 'setColor'
			valueChanges['showresults'] = 'showResults'
			valueChanges['singlepulse'] = 'singlePulse'
		--Event values
			valueChanges['vfx.xscale'] = 'vfx.noteXScale'
			valueChanges['vfx.yscale'] = 'vfx.noteYScale'
			valueChanges['vfx.notexskew'] = 'vfx.noteXSkew'
			valueChanges['vfx.noteyskew'] = 'vfx.noteYSkew'
			valueChanges['monitortheme'] = 'monitorTheme'
		--Event keys
			keyChanges['angleoffset'] = 'angleOffset'
			keyChanges['followplayer'] = 'followPlayer'
			keyChanges['drawlayer'] = 'drawLayer'
			keyChanges['endangle'] = 'endAngle'
			keyChanges['spinease'] = 'spinEase'
			keyChanges['speedmult'] = 'speedMult'
			keyChanges['repeatdelay'] = 'repeatDelay'
			keyChanges['holdease'] = 'holdEase'
			keyChanges['objectname'] = 'objectName'
			keyChanges['newwidth'] = 'newWidth'
		end
		
		local newEvents = {}
		
		local tagNames = {}
		
		local function updateEvent(event)
			local newEvent = {}
			for k,v in pairs(event) do
				local key, value = k,v
				if keyChanges[key] then
					key = keyChanges[key]
				end
				if type(value) == 'string' and valueChanges[value] then
					value = valueChanges[value]
				end
				newEvent[key] = value
			end
			return newEvent
		end
		
		self:iterateEvents(events, function(event)
			local newEvent = {}
			for k,v in pairs(event) do
				local key, value = k,v
				if keyChanges[key] then
					key = keyChanges[key]
				end
				if type(value) == 'string' and valueChanges[value] then
					value = valueChanges[value]
				end
				newEvent[key] = value
			end
			return newEvent
		end, filename, readOnly)
	
		level.metadata.songName = level.metadata.songname
		level.metadata.songname = nil
		
		level.properties.startBeat = level.properties.startbeat
		level.properties.startbeat = nil
		
	end
	
	--format 6
	if level.properties.formatversion < 6 then
		level.properties.formatversion = 6
		
		--find bpm
		local bpm = 100
		for i,v in ipairs(events) do
			if v.type == 'play' then
				bpm = v.bpm
			end
		end
		
		self:iterateEvents(events, function(event)
			if event.type == 'width' then
				--convert from 1/60s to beats
				event.duration = (event.duration)/(3600/bpm)
			end
			return event
			
		end, filename, readOnly)
	end
	
	--format 7
	if level.properties.formatversion < 7 then
		level.properties.formatversion = 7
		level.metadata.artistLink = level.metadata.artistLink or ''
	end
	
	--format 8
	if level.properties.formatversion < 8 then
		level.properties.formatversion = 8
		level.metadata.difficulty = level.metadata.difficulty or 0
	end
	
	--format 9
	if level.properties.formatversion < 9 then
		level.properties.formatversion = 9
		level.metadata.bg = level.metadata.bg or false
	end
	
	--format 10
	if level.properties.formatversion < 10 then
		level.properties.formatversion = 10
		
		self:iterateEvents(events, function(event)
			if event.type == 'deco' then
				--rename old order param to drawOrder
				event.drawOrder = event.order
				event.order = nil
			end
			return event
			
		end, filename, readOnly)
	end
	
	--format 11
	if level.properties.formatversion < 11 then
		level.properties.formatversion = 11
		
		self:iterateEvents(events, function(event)
			if event.type == 'width' then
				event.type = 'paddles'
				event.paddle = 0 --alter all paddles
			end
			
			if event.type == 'paddleCount' then
				--change event to disable all paddles
				event.type = 'paddles'
				local oldOrder = event.order
				event.order = -999
				event.paddle = 0 --alter all paddles
				event.enabled = false
				event.duration = 0
				
				if event.paddles >= 1 then
					local paddleDistance = 360 / event.paddles
					for i = 1, event.paddles do
						table.insert(level.events,
							{
								type = 'paddles',
								angle = event.angle,
								time = event.time,
								order = event.oldOrder or 0,
								enabled = true,
								duration = 0,
								paddle = i,
								newAngle = (i - 1) * paddleDistance
							}
						)
					end
					
				end
				
				
				--clean up unused paddles property
				event.paddles = nil
				
			end
			
			return event
			
		end, filename, readOnly)
	end
	
	--format 12
	if level.properties.formatversion < 12 then
		level.properties.formatversion = 12
		
		self:iterateEvents(events, function(event)
			if event.type == 'deco' or event.type == 'setColor' or event.type == 'ease' then
				if (event.order == 0 or event.order == nil) and (event.duration == 0 or event.duration == nil) then
					event.order = -999
				end
			end
			return event
			
		end, filename, readOnly)
	end
	
	return level, events, saveboth -- return if it got upgraded to force saveBothFiles
	
	
end

function LevelManager:saveLevel(level,filename,saveBothFiles)
	filename = filename or cLevel
	
	local upgraded = false
	level, level.events, upgraded = self:upgradeLevel(level,level.events,filename)
	
	saveBothFiles = saveBothFiles or upgraded
	
	local levelExport = {}
	levelExport.properties = level.properties
	levelExport.metadata = level.metadata
	levelExport.events = {}
	
	local chartExport = {}
	
	for i,v in ipairs(level.events) do
		--just in case
    v.play_onLoad = nil
		v.play_onOffset = nil
		v.play_onBeat = nil
		--may appear in legacy levels
		v.autoplayed = nil
		v.played = nil
		
		if Event.info[v.type] and Event.info[v.type].storeInChart then
			table.insert(chartExport, v)
		else
			table.insert(levelExport.events, v)
		end
		
  end
	
	if saveBothFiles then
		dpf.saveJson(filename .. "level.json",levelExport)
	end
	dpf.saveJson(filename .. "chart.json",chartExport)
	
	return upgraded
	
end


return LevelManager