local st = Gamestate:new('Editor')

st:setInit(function(self)
  --em.init('templateobj',{x=128,y=72})
	
  self.gm = em.init("GameManager")

  self.canv = love.graphics.newCanvas(project.res.x,project.res.y)
	
	self.editMode = true

	self.lastSaved = 0

	--self.newLevel = false
	if not self.newLevel then
		self.level, self.forceSaveBoth = LevelManager:loadLevel(cLevel)
		self.gm:resetLevel()
		self.zoom = self.level.properties.speed or 40
		self:updateBiggestBeat()
		self.lastSaved = love.timer.getTime()
	else
		self.newLevelName = 'new'
		self.forceSaveBoth = true
		self.newLevelSaveInSource = false
	end
	
	self.holdEntityDraw = true
	
	shuv.usePalette = false

	self.lastEditorBeat = 0
	self.editorBeat = 0
	self.drawDistance = 10
	
	self.noteRadius = 8
	
	self.angleSnapValues = {8,12,16,24,32}
	self.angleSnap = 3
	self.customAngleSnap = 32
	
	self.beatSnapValues = {1,2,3,4,6,8,12,16}
	self.beatSnap = 2
	self.customBeatSnap = 16
	
	self.cursorBeat = 0
	self.cursorAngle = 0
	
	self.lastClickX = 0
	self.lastClickY = 0
	self.allowDragging = false
	
	self.selectedEvent = nil
	self.overlappingEvents = nil
	
	self.multiselectStart = nil
	self.multiselectEnd = nil
	self.multiselect = nil
	
	self.copy = nil
	self.copySize = nil
	
	self.overlappingEventsDialogue = false
	
	self.goToBeatDialogue = true
	self.biggestBeat = self.biggestBeat or 0
	self.smallestBeat = self.smallestBeat or 0
	
	self.editorRatemodDialogue = true
	self.rateMod = 1
	
	self.unsavedChanges = false
	self.quitDialogue = false
	
	self.changeToTagDialogue = false
	self.newTagName = ''

	self.deltaTimeRepeatInterval = 1.67 -- Determines how long to wait between actions when holding a key.
	self.deltaTimeCooldown = 0.1 -- Tracks current deltaTime cooldown.

	self.errorDialogue = false
	self.errorHeader = ''
	self.errorMessage = ''
  
  self.toggleScrollSpeed = 1
	
	if self.newLevel then
		self.newLevelDialogue = true
	end
	
	self.levelPropertiesDialogue = false
	
	self.placeEvent = ""
	
	self.eventPalette = {
		{
			name = 'Notes',
			content = {
				'block',
				'hold',
				'inverse',
				'mine',
				'mineHold',
				'side',
				'extraTap'
			}
		},
		{
			name = 'VFX',
			content = {
				'ease',
				'hom',
				'noise',
				'setColor',
				'setBgColor',
				'outline',
				'deco',
				'forcePlayerSprite'
			}
		},
		{
			name = 'Other',
			content = {
				'play',
				'setBPM',
				'showResults',
				'paddles',
				--'width',
				'tag',
				--'paddleCount',
				'setBoolean',
				'bookmark',
			}
		},
	}
	
	for i,v in pairs(self.eventPalette) do
		table.insert(v.content,1,'')
	end
	
	
	self.keybinds = {}
	
	--just save chart
	self:addKeybind(function()
			local upgraded = LevelManager:saveLevel(self.level,cLevel, self.forceSaveBoth)
			if upgraded then
				self.forceSaveBoth = false
				print("NOTICE: upgraded format of level.")
			end
			self.p:hurtPulse()
			self.unsavedChanges = false
		end,
		'just save chart',
		'ctrl','save'
	)
	
	--save both files
	self:addKeybind(function()
			if not maininput:down('alt') then
				LevelManager:saveLevel(self.level,cLevel,true)
				
				self.forceSaveBoth = false
				self.p:hurtPulse()
				self.unsavedChanges = false
			end
			self.lastSaved = love.timer.getTime()
		end,
		'save both files',
		'save'
	)
	--copy
	self:addKeybind(function()
			if self.multiselect then
				self.copy = helpers.copy(self.multiselect.events)
				for i,v in ipairs(self.copy) do
					v.time = v.time - self.multiselectStart
				end
				self.copySize = self.multiselectEnd - self.multiselectStart
				self.p:hurtPulse()
			end
		end,
		'copy',
		'ctrl','c'
	)
	--paste
	self:addKeybind(function()
			if self.copy then
				local newEvents = helpers.copy(self.copy)
				
				self.selectedEvent = nil
				self.multiselect = {}
				self.multiselect.events = {}
				self.multiselect.eventTypes = {}
				
				for i,v in ipairs(newEvents) do
					v.time = v.time + self.cursorBeat
					table.insert(self.level.events,v)
					table.insert(self.multiselect.events,v)
					self.multiselect.eventTypes[v.type] = true
				end
				self.multiselectStart = self.cursorBeat
				self.multiselectEnd = self.cursorBeat + self.copySize
				
				self.unsavedChanges = true
				self:updateBiggestBeat()
				self.p:hurtPulse()
			end
		end,
		'paste',
		'ctrl','v'
	)
	
	--play from start
	self:addKeybind(function()
			self.startBeat = 0
			self:playLevel()
		end,
		'play level from start',
		'ctrl','play'
	)
	--play
	self:addKeybind(function()
			if not maininput:down('ctrl') then
				self.startBeat = self.editorBeat + self.offset - 1
				self:playLevel()
			end
		end,
		'play level from editorBeat',
		'play'
	)
	
	--go to beat
	self:addKeybind(function()
			self.goToBeatDialogue = true
		end,
		'go to beat',
		'ctrl','g'
	)
	
	--level properties
	self:addKeybind(function()
			self.levelPropertiesDialogue = true
			self.unsavedChanges = true
		end,
		'level properties',
		'ctrl','i'
	)

	--delete selected event
	self:addKeybind(function()
		self:deleteSelectedEvent()
	end, 'delete selected event', 'delete')

	self.altSliderHovered = false
	self.altSliderHeld = false
	self.altSliderAngleDiff = 0
	self.startClickFromSlider = false

end)

function st:goToResults() 
	-- TODO: Actually make a results screen here. This function currently exists so the game doesn't crash.
  -- I think best option is a custom end level screen for when you're in debug mode.
	cs.p.bodyPulse = 0
	cs.p.lookRadius = 5
end


function st:beatToRadius(b)
	local currentBeat = self.editorBeat
	return ((b - currentBeat)*self.zoom)+cs.p.paddles[1].paddleWidth + cs.p.paddleDistance
	
end

function st:getBeatSnapValue()
	return self.beatSnapValues[self.beatSnap] or self.customBeatSnap
end
function st:getAngleSnapValue()
	return self.angleSnapValues[self.angleSnap] or self.customAngleSnap
end

function st:snapBeat(b)
	if self.beatSnap == 0 then
		return b
	end
	local snapValue = self:getBeatSnapValue()
	return helpers.round(b*snapValue) / snapValue
end

function st:snapAngle(a)
	if self.angleSnap == 0 then
		return a
	end
	local snapValue = self:getAngleSnapValue()
	return helpers.round(a/(360/snapValue)) * (360/snapValue)
end

function st:getPosition(a,b)
	return helpers.rotate(self:beatToRadius(b),a,project.res.cx,project.res.cy)
end

function st:SelectEvent()
	self.multiselectStart, self.multiselectEnd, self.multiselect = nil,nil,nil
	self.overlappingEvents = {}
	for i,v in ipairs(self.level.events) do
		if Event.shouldEditorDraw[v.type](v, self.editorBeat, self.editorBeat + self.drawDistance) then
			local pos = self:getPosition(v.angle,v.time)
			if helpers.collide(
				{x = mouse.rx, y = mouse.ry, width = 0, height = 0},
				{x = pos[1] - 8, y = pos[2] - 8, width = 16, height = 16}
			) then
			
				table.insert(self.overlappingEvents,i)
				
			end
			
		end
	end
	if #self.overlappingEvents == 1 then
		self.selectedEvent = self.level.events[self.overlappingEvents[1]]
		print('selected ' .. Event.info[self.selectedEvent.type].name .. ' event. ' .. self.selectedEvent.angle .. '|'.. self.selectedEvent.time)
		self.overlappingEventsDialogue = false
		self.unsavedChanges = true
		self:updateBiggestBeat()
	elseif #self.overlappingEvents >= 2 then
		print('overlapping events!!')
		self.overlappingEventsDialogue = true
	end
end

function st:getAngleStep()
	local angleStep = 1
	if self.angleSnap ~= 0 then
		local snapValue = self:getAngleSnapValue()
		angleStep = 360/snapValue
	end
	return angleStep
end


function st:getBeatStep()
	local beatStep = 1
	if self.beatSnap ~= 0 then
		local snapValue = self:getBeatSnapValue()
		beatStep = 1/snapValue
	end
	return beatStep
end

function st:playLevel()
  self.editMode = false
	shuv.usePalette = true
	mouse:enableGameplay()
  self.gm:resetLevel()
	
  --self.gm.on = true
end

function st:stopLevel()
  self.editMode = true
	shuv.usePalette = false
  self.startBeat = 0

	mouse:disableGameplay()
	self.gm:stopLevel()

	self.gm:resetLevel()
	--self.gm.on = false
	pq = ""
	self.noteRadius = 8
	
	entities = {self.p}
end

function st:leave()
	mouse:disableGameplay()
  self.gm:stopLevel()
	shuv.usePalette = true
  entities = {}
end

function st:addKeybind(func,name,k1,k2,k3)
	table.insert(self.keybinds,{func = func, name = name, k1 = k1, k2 = k2, k3 = k3})
end

function st:checkKeybinds()
	for i,v in ipairs(self.keybinds) do
		if v.k1 and v.k2 and v.k3 then
			if maininput:down(v.k1) and maininput:down(v.k2) and maininput:pressed(v.k3) then
				print('pressed keybind ' .. v.name)
				v.func()
			end
		elseif v.k1 and v.k2 then
			if maininput:down(v.k1) and maininput:pressed(v.k2) then
				print('pressed keybind ' .. v.name)
				v.func()
			end
		else
			if maininput:pressed(v.k1) then
				print('pressed keybind ' .. v.name)
				v.func()
			end
		end
	end
end

function st:updateBiggestBeat()
	self.biggestBeat = 0
	self.smallestBeat = 0
	for i,v in ipairs(self.level.events) do
		self.biggestBeat = math.max(self.biggestBeat,v.time)
		self.smallestBeat = math.min(self.smallestBeat,v.time)
	end
end

function st:deleteSelectedEvent()
	for i, v in ipairs(self.level.events) do
		if v == self.selectedEvent then
			table.remove(self.level.events, i)
			print("deleted event")
			self.selectedEvent = nil
			self.unsavedChanges = true
			self:updateBiggestBeat()
			break
		end
	end
end


function st:playbackError(message)
	self.errorDialogue = true
	self.errorMessage = message
	self.errorHeader = "An error has occured during playback."
	self:stopLevel()
end

st:setUpdate(function(self,dt)
  if not paused then
		
		if self.newLevel then
			if self.doQuit then
				self:leave()
				cs = bs.load(returnData.state)
				for k,v in pairs(returnData.vars) do
					cs[k] = v
				end
				cs:init()
			end
			return
		end
		
		if self.editMode then
			self:checkKeybinds()
			
			self.cursorAngle = (helpers.anglePoints(project.res.cx,project.res.cy,mouse.rx,mouse.ry) + 360) % 360
			self.cursorBeat = math.max((math.sqrt((mouse.rx-project.res.cx)^2+(mouse.ry-project.res.cy)^2) - self:beatToRadius(self.editorBeat))/self.zoom, 0) + self.editorBeat
			
			self.cursorAngle = self:snapAngle(self.cursorAngle)
			self.cursorBeat = self:snapBeat(self.cursorBeat)
			if self.cursorBeat < self.editorBeat then
				self.cursorBeat = self.cursorBeat + (1/self:getBeatSnapValue())
			end
			
			if mouse.sy ~= 0 then
				if maininput:down('ctrl') then
					self.zoom = math.min(math.max(self.zoom+mouse.sy*2,20),100)
				else
					self.lastEditorBeat = self.editorBeat
          local scrollSpeed = self.toggleScrollSpeed == 1 and 5 or 2
					self.editorBeat = math.max(self.editorBeat + (mouse.sy * scrollSpeed) / self.zoom,self.smallestBeat)
					if self.beatSnap ~= 0 then
						local snappedBeat = self:snapBeat(self.editorBeat)
						if math.abs(self.editorBeat-snappedBeat) <= 0.05 and math.abs(self.editorBeat-snappedBeat) <= math.abs(self.lastEditorBeat-snappedBeat)then
							self.editorBeat = snappedBeat
						end
					end
				end
			end

			if mouse.pressed == 1 and not self.altSliderHeld and not self.startClickFromSlider then -- on mouse press
				self.lastClickX,self.lastClickY = mouse.rx,mouse.ry
				self.allowDragging = false
				self.deletePending = false
				self.selectedEvent = nil -- clears the currently selected event. this may be a controversial change but it makes my life easier.
				if maininput:down('shift') then --multiselect 
					if (not self.multiselectStart) and (not self.multiselectEnd) then
						self.multiselectStart = self.cursorBeat
					else
						if not self.multiselectEnd then
							self.multiselectEnd = self.cursorBeat
							if self.multiselectEnd < self.multiselectStart then
								self.multiselectStart, self.multiselectEnd = self.multiselectEnd, self.multiselectStart
							end
							
							self.selectedEvent = nil
							self.multiselect = {}
							self.multiselect.events = {}
							self.multiselect.eventTypes = {}
							for i,v in ipairs(self.level.events) do
								if v.time >= self.multiselectStart and v.time <= self.multiselectEnd then 
									table.insert(self.multiselect.events,v)
									self.multiselect.eventTypes[v.type] = true
								end
							end
							
						else
							self.multiselectStart = self.cursorBeat
							self.multiselectEnd = nil
							self.multiselect = nil
						end
					end
				else --select/place
					
					self:SelectEvent()

					if #self.overlappingEvents == 0 then
						--place new event
						if self.placeEvent ~= '' and Event.info[self.placeEvent] then
							table.insert(self.level.events,{type = self.placeEvent, time = self.cursorBeat, angle = self.cursorAngle})
							self.selectedEvent = self.level.events[#self.level.events]
							self.unsavedChanges = true
							self:updateBiggestBeat()
						else
							self.placeEvent = ''
						end
					end
				end
				
			elseif mouse.pressed > 1 and not self.altSliderHeld and not self.startClickFromSlider and self.selectedEvent then
				-- The user is holding the mouse! That means they wish to DRAG (yass)
				if helpers.distance({self.lastClickX,self.lastClickY},{mouse.rx,mouse.ry}) >= 10 then
					self.allowDragging = true
				end
				if self.allowDragging then
					self.selectedEvent.angle = self.cursorAngle
					self.selectedEvent.time = self.cursorBeat
				end
			end
			
			if maininput:pressed("back") then
				if self.unsavedChanges then
					self.quitDialogue = true
				else
					self.doQuit = true
				end
			end
			if self.doQuit then
				self:leave()
				cs = bs.load(returnData.state)
				for k,v in pairs(returnData.vars) do
					cs[k] = v
				end
				cs:init()
			end
			
			if mouse.altpress == -1 then -- Delete hovered events
				self.selectedEvent = nil
				self:SelectEvent()
				if #self.overlappingEvents == 1 then
					self:deleteSelectedEvent()
				else
					self.deletePending = true
				end
			end

			if self.deletePending == true and self.selectedEvent ~= nil then
				self:deleteSelectedEvent()
				self.deletePending = false
			end

			-- Sets deltaTimeCooldown to -1 if a key has just been pressed. This prevents delay when mashing keys to scrub.
			if maininput:pressed("move_left") or maininput:pressed("move_right") then
				self.deltaTimeCooldown = -1
			end

			-- Input checking for recurring inputs.

			if self.deltaTimeCooldown <= 0 then

				if maininput:down("move_up") and self.selectedEvent then
					-- Moves up a step.
					self.selectedEvent.time = self.selectedEvent.time + 1 / self:getBeatSnapValue()
					self.deltaTimeCooldown = 4*self.deltaTimeRepeatInterval

					if maininput:pressed("move_up") then
						self.deltaTimeCooldown = self.deltaTimeCooldown + 2.5
					end
				end

				if maininput:down("move_down") and self.selectedEvent then
					-- Moves down a step.
					self.selectedEvent.time = self.selectedEvent.time - 1 / self:getBeatSnapValue()
					self.deltaTimeCooldown = 4*self.deltaTimeRepeatInterval

					if maininput:pressed("move_down") then
						self.deltaTimeCooldown = self.deltaTimeCooldown + 2.5
					end
				end

				-- Move left with left arrow
				if maininput:down("move_left") and self.selectedEvent then
					-- Sets deltatime window back to the interval.

					-- If they are not holding modifier key, the interval is set to 3* to prevent it spinning too quick
					local newangle
					if not maininput:down('modifier') then
						newangle = self.selectedEvent.angle - 360 / (self:getAngleSnapValue())
						self.deltaTimeCooldown = 3 * self.deltaTimeRepeatInterval
					else
						newangle = self.selectedEvent.angle - 1
						self.deltaTimeCooldown = self.deltaTimeRepeatInterval
					end
					self.selectedEvent.angle = newangle

					if self.selectedEvent.angle < 0 then
						self.selectedEvent.angle = self.selectedEvent.angle + 360 -- Bounds checking to prevent angles that are stupid.
					end

					-- the user has just pressed the button. let's wait another ???ms before moving.
					if maininput:pressed('move_left') then
						self.deltaTimeCooldown = self.deltaTimeCooldown + 2.5
					end


				end

				-- Move right with right arrow
				if maininput:down("move_right") and self.selectedEvent then
					-- this does the same as above but the opposite way around because you're holding right
					-- there's probably a cleaner way to do this. sue me. -- bliv

					local newangle
					if not maininput:down('modifier') then
						newangle = self.selectedEvent.angle + 360 / (self:getAngleSnapValue())
						self.deltaTimeCooldown = 3 * self.deltaTimeRepeatInterval
					else
						newangle = self.selectedEvent.angle + 1
						self.deltaTimeCooldown = self.deltaTimeRepeatInterval
					end
					self.selectedEvent.angle = newangle
					if self.selectedEvent.angle > 360 then
						self.selectedEvent.angle = self.selectedEvent.angle - 360
					end

					-- the user has just pressed the button. let's wait another ???ms before moving.
					if maininput:pressed('move_right') then
						self.deltaTimeCooldown = self.deltaTimeCooldown + 7.5
					end

				end



			else
				self.deltaTimeCooldown = self.deltaTimeCooldown - dt
			end
			--alt slider stuff
			local prevBookmarkBeat = 0
			local currBookmarkBeat = 0
			local nextBookmarkBeat = self.biggestBeat
			
			for i,v in ipairs(self.level.events) do
				if v.type == "bookmark" and v.name ~= '' and v.time <= self.editorBeat and v.time > currBookmarkBeat then
					currBookmarkBeat = v.time
					if v.time ~= self.editorBeat then
						prevBookmarkBeat = v.time
					end
				elseif v.type == "bookmark" and v.name ~= '' and v.time > self.editorBeat and v.time < nextBookmarkBeat then
					nextBookmarkBeat = v.time
				end
			end
			
			--prevBookmarkBeat = beat 0, editorBeat - prevBookmarkBeat = curr beat, nextBookmarkBeat - prevBookmarkBeat = biggest beat, practically
			
			--local cAngle = 2*math.pi*self.editorBeat/self.biggestBeat
			--local cX = project.res.cx + (self:beatToRadius(self.editorBeat)-4) * math.sin(cAngle)
			--local cY = project.res.cy - (self:beatToRadius(self.editorBeat)-4) * math.cos(cAngle)
			
			local cAngle = 2*math.pi*(self.editorBeat - currBookmarkBeat)/(nextBookmarkBeat - currBookmarkBeat)
			local cX = project.res.cx + (self:beatToRadius(self.editorBeat)-4) * math.sin(cAngle)
			local cY = project.res.cy - (self:beatToRadius(self.editorBeat)-4) * math.cos(cAngle)
			
			if math.pow((mouse.rx-cX), 2) + math.pow((mouse.ry-cY), 2) <= 16 then
				self.altSliderHovered = true
			else
				self.altSliderHovered = false
			end

			--click on slider
			if mouse.pressed == 1 and maininput:down('alt') then
				local mX = mouse.rx - project.res.cx
				local mY = mouse.ry - project.res.cy
				
				if self.altSliderHovered then
					self.altSliderHeld = true
					
					self.altSliderAngleDiff = ((self.editorBeat - currBookmarkBeat) / (nextBookmarkBeat - currBookmarkBeat)) - (0.5 + math.atan2(-mX, mY) / (2*math.pi))
					if self.altSliderAngleDiff > 0.5 then
						self.altSliderAngleDiff = self.altSliderAngleDiff - 1
					elseif self.altSliderAngleDiff < -0.5 then
						self.altSliderAngleDiff = self.altSliderAngleDiff + 1
					end
				elseif math.abs(math.sqrt(math.pow(mX, 2) + math.pow(mY, 2))-self:beatToRadius(self.editorBeat)+4) < 2 then
					self.altSliderHeld = true
				end
			elseif (mouse.pressed == -1) or (not maininput:down('alt')) then
				self.altSliderHeld = false
				self.altSliderAngleDiff = 0
			end
			
			if self.altSliderHeld then
				local mX = mouse.rx - project.res.cx
				local mY = mouse.ry - project.res.cy
				local newFraction = (0.5 + math.atan2(-mX, mY) / (2*math.pi) + self.altSliderAngleDiff) % 1
				if math.abs(newFraction - ((self.editorBeat - currBookmarkBeat) / (nextBookmarkBeat - currBookmarkBeat))) > 0.002 then
					self.altSliderAngleDiff = self.altSliderAngleDiff * 0.85
				end
				self.editorBeat = currBookmarkBeat + (nextBookmarkBeat - currBookmarkBeat) * newFraction
				--jump left
				if newFraction - (cAngle / (2*math.pi)) > 0.5 then
					self.editorBeat = currBookmarkBeat - 0.05
				--jump right
				elseif newFraction - (cAngle / (2*math.pi)) < -0.5 then
					self.editorBeat = nextBookmarkBeat + 0.05
				end
				--loop around the level
				if self.editorBeat < 0 then
					self.editorBeat = self.editorBeat + self.biggestBeat
				elseif self.editorBeat > self.biggestBeat then
					self.editorBeat = self.editorBeat - self.biggestBeat
				end
			end
			
			--alt+left/right
			if maininput:pressed('move_left') and maininput:down('alt') then
				self.editorBeat = prevBookmarkBeat
			elseif maininput:pressed('move_right') and maininput:down('alt') then
				self.editorBeat = nextBookmarkBeat
			end
			
			
			
			--prevent placing an event if alt is released early
			if self.altSliderHeld then
				self.startClickFromSlider = true
			elseif self.startClickFromSlider and mouse.pressed == -1 then
				self.startClickFromSlider = false
			end
			
			if self.editMode then
				self.cBeat = self.editorBeat --for hold rendering
			end

			--trigger auto-backup every five minutes
			if love.timer.getTime() - self.lastSaved > 300 then
				LevelManager:saveLevel(self.level,cLevel.."/backup/",true)
				self.lastSaved = love.timer.getTime()
			end

		else
			self.gm:update(dt)
			
			if maininput:pressed("back") then
				self:stopLevel()
			end
			
			if maininput:pressed("play") then
				self.editorBeat = self.cBeat
				self:stopLevel()
			end

		end
		
		
		
	end
end)

function st:imgui()
	
	--imgui
	if project.useImgui then
		
		prof.push("editor imgui")
		imgui.SetNextWindowPos(950, 50, "ImGuiCond_Once")
		imgui.SetNextWindowSize(250, 540, "ImGuiCond_Once")
		imgui.Begin("Event Editor")
			
			if self.multiselect then
				imgui.Text('Selecting ' .. #self.multiselect.events .. ' events')
				imgui.Separator()
				imgui.Text('Types:')
				for k,_ in pairs(self.multiselect.eventTypes) do
					if imgui.Button('Only##'..k) then
						
						local newEvents = {}
						for i,v in ipairs(self.multiselect.events) do
							if v.type == k then
								table.insert(newEvents,v)
							end
						end
						
						self.multiselect.events = newEvents
						
						self.multiselect.eventTypes = {}
						self.multiselect.eventTypes[k] = true
					end
					imgui.SameLine()
					if imgui.Button('Remove##'..k) then
						
						local newEvents = {}
						for i,v in ipairs(self.multiselect.events) do
							if v.type ~= k then
								table.insert(newEvents,v)
							end
						end
						
						self.multiselect.events = newEvents
						
						self.multiselect.eventTypes[k] = nil
					end
					imgui.SameLine()
					imgui.Text(Event.info[k].name)
					
				end
				
				imgui.Separator()
				local beatStep = 0.01
				local angleStep = 1
				if self.beatSnap ~= 0 then
					beatStep = 1/self:getBeatSnapValue()
				end
				if self.angleSnap ~= 0 then
					angleStep = 360/self:getAngleSnapValue()
				end
				
				local deltaAngle = 0
				local deltaBeat = 0
				local deltaScale = 1
				imgui.Text('Rotate all')
				imgui.SameLine()
				if imgui.Button('-##angleminus') then
					deltaAngle = deltaAngle - angleStep
				end
				imgui.SameLine()
				if imgui.Button('+##angleplus')  then
					deltaAngle = deltaAngle + angleStep
				end
				
				imgui.Text('Retime all')
				imgui.SameLine()
				if imgui.Button('-##beatminus') then
					deltaBeat = deltaBeat - beatStep
				end
				imgui.SameLine()
				if imgui.Button('+##beatplus')  then
					deltaBeat = deltaBeat + beatStep
				end
				
				imgui.Separator()
				
				if imgui.Button('Flip Horiz') then
					deltaScale = -1
				end
				imgui.SameLine()
				if imgui.Button('Flip Vert') then
					deltaScale = -1
					deltaAngle = -180
				end
				
				
				if deltaAngle ~= 0 or deltaBeat ~= 0 or deltaScale ~= 1 then
					for i,v in ipairs(self.multiselect.events) do
						v.angle = v.angle * deltaScale + deltaAngle
						if v.angle2 then
							v.angle2 = v.angle2 * deltaScale + deltaAngle
						end
						v.time = v.time + deltaBeat
					end
					self.multiselectStart = self.multiselectStart + deltaBeat
					self.multiselectEnd = self.multiselectEnd + deltaBeat
					self.unsavedChanges = true
					self:updateBiggestBeat()
				end
				
				imgui.Separator()
				if imgui.Button('Change to tag') then
					self.changeToTagDialogue=true
					self.newTagName = ''
				end
				imgui.Separator()
				if imgui.Button('Delete selected events') then
					for i,v in ipairs(self.multiselect.events) do
						for _i,_v in ipairs(self.level.events) do
							if _v == v then
								table.remove(self.level.events, _i)
							end
						end
					end
					self.multiselect.events = {}
					self.unsavedChanges = true
					self:updateBiggestBeat()
				end
				if #self.multiselect.events == 0 then
					self.multiselect = nil
					self.multiselectStart = nil
					self.multiselectEnd = nil
				end
				
			elseif self.selectedEvent then
				imgui.Text("Editing " .. Event.info[self.selectedEvent.type].name)
				imgui.Separator()
				
				--default properties that all events have
				local beatStep = 0.01
				local angleStep = 1
				if self.beatSnap ~= 0 then
					beatStep = 1/self:getBeatSnapValue()
				end
				if self.angleSnap ~= 0 then
					angleStep = 360/self:getAngleSnapValue()
				end
				Event.property(self.selectedEvent, 'decimal', 'time', 'Beat to activate on', {step = beatStep})
				Event.property(self.selectedEvent, 'decimal', 'angle', 'Angle to activate at', {step = angleStep})
				Event.property(self.selectedEvent, 'int', 'order', 'Order to run on, lower = first',{optional = true, default = 0})
				
				if Event.editorProperties[self.selectedEvent.type] then
					Event.editorProperties[self.selectedEvent.type](self.selectedEvent)
				end
				imgui.Separator()
				if imgui.Button('Delete event') then
					self:deleteSelectedEvent()
				end
				
			else
				imgui.Text("Select an event to edit it")
				
				--self.zoom = imgui.SliderInt("Zoom level", self.zoom, 0, 100);
				
				
			end
		
		
		imgui.SetNextWindowPos(0, 50, "ImGuiCond_Once")
		imgui.SetNextWindowSize(150, 300, "ImGuiCond_Once")
		imgui.Begin("Event palette")
			self.placeEvent = imgui.InputText("##placeEvent",self.placeEvent,9999)
			if imgui.BeginTabBar("Event Type") then

				for i, tab in pairs(self.eventPalette) do
					
					if imgui.BeginTabItem(tab.name) then
						
						
						if imgui.ListBoxHeader('##tab'..tab.name) then
							for ii, v in ipairs(tab.content) do
								local displayEventName = 'None'
								local eventName = v
								if v ~= '' then
									displayEventName = Event.info[v].name
								end
								
								local selected = (self.placeEvent == eventName)
								
								if imgui.Selectable(displayEventName, selected) then
									self.placeEvent = eventName
								end
								
								if selected then
									imgui.SetItemDefaultFocus()
								end
								
							end
							imgui.ListBoxFooter()
						end
						
						
						imgui.EndTabItem()
					end
				end
			
				imgui.EndTabBar()
        
        imgui.Separator()
        
        local scrollSpeedNames = {"Mouse", "Trackpad"}
        imgui.Text("Scroll Speed")
        self.toggleScrollSpeed = imgui.SliderInt("##scrollspeed", self.toggleScrollSpeed, 1, 2, 
          scrollSpeedNames[self.toggleScrollSpeed], {"ImGuiSliderFlags_NoInput"})
			end
		
		imgui.End()
		
		imgui.SetNextWindowPos(0, 630, "ImGuiCond_Once")
		imgui.SetNextWindowSize(150, 90, "ImGuiCond_Once")
		imgui.Begin("Snap")
			--angle
			local angleSnapText = 'None'
			
			if imgui.Button('-##angleminus') then
				self.angleSnap = self.angleSnap - 1 
			end
			imgui.SameLine()
			if imgui.Button('+##angleplus')  then
				self.angleSnap = self.angleSnap + 1 
			end
			
			if self.angleSnap == -2 then
				self.angleSnap = #self.angleSnapValues
			elseif self.angleSnap > #self.angleSnapValues then
				self.angleSnap = -1
			end
			
			if self.angleSnap ~= 0 then
				angleSnapText = '1/' .. self:getAngleSnapValue()
			end
			
	
			
			imgui.SameLine()
			if self.angleSnap == -1 then
				imgui.Text("Angle: 1/")
				imgui.SameLine()
				self.customAngleSnap = imgui.InputInt('##customangle',self.customAngleSnap)
				self.customAngleSnap = math.max(self.customAngleSnap,1)
			else
				imgui.Text("Angle: " .. angleSnapText)
				
			end
			imgui.Separator()
			
			--beat
			local beatSnapText = 'None'
			
			if imgui.Button('-##beatminus') then
				self.beatSnap = self.beatSnap - 1 
			end
			imgui.SameLine()
			if imgui.Button('+##beatplus')  then
				self.beatSnap = self.beatSnap + 1 
			end
			
			if self.beatSnap == -2 then
				self.beatSnap = #self.beatSnapValues
			elseif self.beatSnap > #self.beatSnapValues then
				self.beatSnap = -1
			end
			
			if self.beatSnap ~= 0 then
				beatSnapText = '1/' .. self:getBeatSnapValue()
			end
			
			imgui.SameLine()
			if self.beatSnap == -1 then
				imgui.Text("Beat: 1/")
				imgui.SameLine()
				self.customBeatSnap = imgui.InputInt('##custombeat',self.customBeatSnap)
				self.customBeatSnap = math.max(self.customBeatSnap,1)
			else
				imgui.Text("Beat: " .. beatSnapText)
				
			end
		imgui.End()
		
		if self.overlappingEventsDialogue then
			imgui.SetNextWindowPos(190, 240, "ImGuiCond_Once")
			imgui.SetNextWindowSize(240, 240, "ImGuiCond_Once")
			self.overlappingEventsDialogue = imgui.Begin("Overlapping events!",true)
			
			if self.deletePending then
				imgui.Text("Select which event to delete:")
			else
				imgui.Text("Select which event to edit:")
			end

			imgui.Separator()
			for i,v in ipairs(self.overlappingEvents) do
				local e = self.level.events[v]
				if imgui.Selectable(Event.info[e.type].name .. ' (ID '.. v..')') then
					self.overlappingEventsDialogue = false
					self.selectedEvent = self.level.events[v]
					self.unsavedChanges = true
					self:updateBiggestBeat()
				end
			end
			imgui.End()
		end
		if self.goToBeatDialogue then
			imgui.SetNextWindowPos(950, 616, "ImGuiCond_Once")
			imgui.SetNextWindowSize(250, 100, "ImGuiCond_Once")
			self.goToBeatDialogue = imgui.Begin("Go to beat",true)
			
			imgui.PushItemWidth(200)
			self.editorBeat = imgui.InputFloat("", self.editorBeat, self:getBeatStep(), 1, 3)
			self.editorBeat = imgui.SliderFloat('##slidergotobeat',self.editorBeat,self.smallestBeat,math.max(math.ceil(self.editorBeat),self.biggestBeat))
			imgui.PopItemWidth()
			
			imgui.End()
		end
		if self.quitDialogue then
			imgui.SetNextWindowPos(480, 230, "ImGuiCond_Once")
			imgui.SetNextWindowSize(240, 124, "ImGuiCond_Once")
			self.quitDialogue = imgui.Begin("Unsaved changes!",true)
			
			imgui.Text("Are you *sure* you want to quit?")
			imgui.Separator()
			if imgui.Button('Save and quit') then
				LevelManager:saveLevel(self.level,cLevel,true)
				self.doQuit = true
			end
			if imgui.Button('Quit without saving') then
				self.doQuit = true
			end
			if imgui.Button('Cancel') then
				self.quitDialogue = false
			end
			imgui.End()
		end
		
		if self.changeToTagDialogue and (not self.multiselect) then
			self.changeToTagDialogue = false
		end
		
		if self.changeToTagDialogue then
			imgui.SetNextWindowPos(480, 230, "ImGuiCond_Once")
			imgui.SetNextWindowSize(240, 124, "ImGuiCond_Once")
			self.changeToTagDialogue = imgui.Begin("Change to tag",true)
			self.newTagName = imgui.InputText("Tag name",self.newTagName,9999)

			if imgui.Button('Make tag') then
				
				local tagEvents = helpers.copy(self.multiselect.events)
				for i,v in ipairs(tagEvents) do
					v.time = v.time - self.multiselectStart
				end
				
				dpf.saveJson(cLevel .. "tags/" .. self.newTagName..'.json',tagEvents)
				
				for i,v in ipairs(self.multiselect.events) do
					for _i,_v in ipairs(self.level.events) do
						if _v == v then
							table.remove(self.level.events, _i)
						end
					end
				end
				self.multiselect.events = {}
				self.unsavedChanges = true
				
				table.insert(self.level.events,{type = 'tag', angle = 0, time = self.multiselectStart, tag = self.newTagName, angleOffset = false})
				
				self:updateBiggestBeat()
				
				self.changeToTagDialogue = false
			end
			if imgui.Button('Cancel') then
				self.changeToTagDialogue = false
			end
			imgui.End()
		end
		
		
		if self.newLevelDialogue then
			local okToContinue
			imgui.SetNextWindowPos(370, 220, "ImGuiCond_Once")
			imgui.SetNextWindowSize(390, 240, "ImGuiCond_Once")
			self.newLevelDialogue = imgui.Begin("New level",true)
				imgui.Text("Filename: " .. cLevel)
				imgui.SameLine()
				self.newLevelName = imgui.InputText("##newLevelName",self.newLevelName,9999)
			
				if imgui.Button('Create level') then
					okToContinue = true
					self.newLevelDialogue = false
				end
				if imgui.Button('Cancel') then
					self.newLevelDialogue = false
				end
				
				if (not love.filesystem.isFused()) then
					self.newLevelSaveInSource = imgui.Checkbox('Save in source code?', self.newLevelSaveInSource)
				end
			
			imgui.End()
			
			if not self.newLevelDialogue then
				if okToContinue then
					if love.filesystem.getInfo(cLevel..self.newLevelName..'/chart.json') then
						--error("Chart at directory " .. cLevel..self.newLevelName .. " already exists!")
						self.errorDialogue = true
						self.errorMessage = "Level with name \"" .. self.newLevelName .. "\" already exists. Cannot overwrite."
						self.errorHeader = "Could not create level."

						self.newLevelDialogue = true
					else
						love.filesystem.forceSaveInSource(self.newLevelSaveInSource)
						self.level = LevelManager:newLevel(cLevel..self.newLevelName..'/')
						love.filesystem.forceSaveInSource(false)
						self.gm:resetLevel()
						self.zoom = self.level.properties.speed or 60
						self.lastSaved = love.timer.getTime()
						self.newLevel = false
						love.system.openURL("file://"..love.filesystem.getRealDirectory(cLevel)..'/'..cLevel)
					end
					
				else
					--print user cancelled out of making a level
					self.doQuit = true
					
				end
			end
			
			
			
		end
		
		if self.levelPropertiesDialogue then
			imgui.SetNextWindowPos(370, 170, "ImGuiCond_Once")
			imgui.SetNextWindowSize(390, 350, "ImGuiCond_Once")
			self.levelPropertiesDialogue = imgui.Begin("Level properties",true)
				imgui.Text("--METADATA--")
				self.level.metadata.songName = imgui.InputText("Song name",self.level.metadata.songName,9999)
				self.level.metadata.artist = imgui.InputText("Artist",self.level.metadata.artist,9999)
				self.level.metadata.artistLink = imgui.InputText("Artist Link",self.level.metadata.artistLink,9999)
				self.level.metadata.charter = imgui.InputText("Charter",self.level.metadata.charter,9999)
				self.level.metadata.description = imgui.InputTextMultiline("Description",self.level.metadata.description,9999)

				
				self.level.metadata.difficulty = imgui.InputInt('Difficulty', self.level.metadata.difficulty)
				
				imgui.Separator()
				imgui.Text("--BG--")
				self.level.metadata.bg = imgui.Checkbox('Song Select BG?', self.level.metadata.bg)
				if self.level.metadata.bg then
					self.level.metadata.bgData = self.level.metadata.bgData or {
						image = '',
						redChannel = {r=255,g=0,b=0},
						blueChannel = {r=0,g=0,b=255}
					}
					if not self.level.metadata.bgData.greenChannel then
						self.level.metadata.bgData.greenChannel = {r=255,g=255,b=255}
						self.level.metadata.bgData.yellowChannel = {r=255,g=255,b=255}
						self.level.metadata.bgData.magentaChannel = {r=255,g=255,b=255}
						self.level.metadata.bgData.cyanChannel = {r=255,g=255,b=255}
						
					end
					local bgData = self.level.metadata.bgData
					bgData.image = imgui.InputText("image",bgData.image,9999)
					bgData.redChannel.r,bgData.redChannel.g,bgData.redChannel.b = helpers.imguiColor('Red channel',bgData.redChannel.r,bgData.redChannel.g,bgData.redChannel.b)
					bgData.blueChannel.r,bgData.blueChannel.g,bgData.blueChannel.b = helpers.imguiColor('Blue channel',bgData.blueChannel.r,bgData.blueChannel.g,bgData.blueChannel.b)
					bgData.greenChannel.r,bgData.greenChannel.g,bgData.greenChannel.b = helpers.imguiColor('Green channel',bgData.greenChannel.r,bgData.greenChannel.g,bgData.greenChannel.b)
					bgData.yellowChannel.r,bgData.yellowChannel.g,bgData.yellowChannel.b = helpers.imguiColor('Yellow channel',bgData.yellowChannel.r,bgData.yellowChannel.g,bgData.yellowChannel.b)
					bgData.magentaChannel.r,bgData.magentaChannel.g,bgData.magentaChannel.b = helpers.imguiColor('Magenta channel',bgData.magentaChannel.r,bgData.magentaChannel.g,bgData.magentaChannel.b)
					bgData.cyanChannel.r,bgData.cyanChannel.g,bgData.cyanChannel.b = helpers.imguiColor('Cyan channel',bgData.cyanChannel.r,bgData.cyanChannel.g,bgData.cyanChannel.b)
					
				else
					self.level.metadata.bgData = nil
				end
				
				
				imgui.Separator()
				imgui.Text("--OTHER--")
				
				self.level.properties.offset = imgui.InputFloat("Spawn offset", self.level.properties.offset, 1, 1, 3)
				self.level.properties.startBeat = imgui.InputFloat("Start beat", self.level.properties.startBeat, 1, 1, 3)
				
				local loadBeatEnable = imgui.Checkbox('##checkboxloadbeat',(self.level.properties.loadBeat ~= nil))
				imgui.SameLine()
				if loadBeatEnable then
					self.level.properties.loadBeat = self.level.properties.loadBeat or -1
					self.level.properties.loadBeat = imgui.InputFloat("##floatloadbeat", self.level.properties.loadBeat, 1, 1, 3)
					imgui.SameLine()
				else
					self.level.properties.loadBeat = nil
				end
				
				imgui.Text("Load beat")
				imgui.SameLine()
				helpers.imguiHelpMarker("Events on or before this beat will be run as soon as the level is loaded.")
				
				
				self.level.properties.speed = imgui.InputFloat("Speed", self.level.properties.speed, 1, 1, 3)
				
				
			imgui.End()
		end
		
		if self.editorRatemodDialogue then
		
			imgui.SetNextWindowPos(370, 10, "ImGuiCond_Once")
			imgui.SetNextWindowSize(390, 60, "ImGuiCond_Once")
			self.editorRatemodDialogue = imgui.Begin("Playback speed",true)
				local rateModSpeedMin = 0.25
				local rateModSpeedMax = 2
				self.rateMod = imgui.SliderFloat('Speed (' .. rateModSpeedMin .. 'x-' .. rateModSpeedMax .. 'x)', self.rateMod, rateModSpeedMin, rateModSpeedMax)
				self.rateMod = math.floor(self.rateMod * 20 + 0.5)/20
			imgui.End()
		end
    
		if self.errorDialogue  then
			imgui.SetNextWindowPos(400, 200, "ImGuiCond_Once")
			imgui.SetNextWindowSize(400, 200, "ImGuiCond_Once")
			self.errorDialogue = imgui.Begin(self.errorHeader,true)
			
			imgui.TextWrapped(self.errorMessage)

			if imgui.Button('OK') then
				self.errorDialogue = false
			end
			imgui.End()
		end
		
		
		prof.pop("editor imgui")
		
	end
	
end

st:setFgDraw(function(self)
  color('white')
  love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
  love.graphics.setCanvas(self.canv)
  
	if self.editMode then
		love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)


		
		self:imgui()
		
		
		if self.newLevel then 
			return
		end
		
		love.graphics.setLineWidth(2)
		love.graphics.setColor(0.75,0.75,0.75,1)
		
		--draw angle snap lines
		if self.angleSnap ~= 0 then
			for i=0,self:getAngleSnapValue() - 1 do
				local pos = helpers.rotate(400,i*(360/self:getAngleSnapValue()),project.res.cx,project.res.cy)
				love.graphics.line(project.res.cx,project.res.cy,pos[1],pos[2])
			end
		end
		
		--draw beat lines / beat snap
		for i=0, self.drawDistance do
			color('black')
			love.graphics.circle("line",project.res.cx,project.res.cy,self:beatToRadius(math.ceil(self.editorBeat) + i))
			if self.beatSnap ~= 0 then
				
				love.graphics.setColor(0.75,0.75,0.75,1)
				for ii=1,self:getBeatSnapValue()-1 do
					local snapRad = self:beatToRadius(math.floor(self.editorBeat) + i + (ii / self:getBeatSnapValue()))
					if snapRad > self:beatToRadius(self.editorBeat) then
						love.graphics.circle("line",project.res.cx,project.res.cy,snapRad)
					end
				end
			end
		end
		
		--circle around center
		color('black')
		love.graphics.circle("line",project.res.cx,project.res.cy,self:beatToRadius(self.editorBeat))
		
		
		--multiselect
		love.graphics.setColor(0,1,0,1)
		if self.multiselectStart then
			love.graphics.circle("line",project.res.cx,project.res.cy,self:beatToRadius(math.max(self.multiselectStart, self.editorBeat)))
		end
		if self.multiselectEnd then
			love.graphics.circle("line",project.res.cx,project.res.cy,self:beatToRadius(math.max(self.multiselectEnd, self.editorBeat)))
		end
		
		--draw player
		if not maininput:down('alt') then
			em.draw()
		end
		
		--draw bookmark rings
		for i,v in ipairs(self.level.events) do
			if v.type == "bookmark" and v.time > self.editorBeat and v.time < (self.editorBeat + self.drawDistance) then --am i doing this properly
				love.graphics.setColor(love.math.colorFromBytes(v.r, v.g, v.b))
				love.graphics.circle("line", project.res.cx, project.res.cy, self:beatToRadius(v.time))
			end
		end
		
		color()
		
		for i,v in ipairs(self.level.events) do --draw events
			if Event.shouldEditorDraw[v.type](v, self.editorBeat, self.editorBeat + self.drawDistance) then
				local pos = self:getPosition(v.angle,v.time)
				if Event.editorDraw[v.type] then
					Event.editorDraw[v.type](v, self.editorBeat, self.editorBeat + self.drawDistance)
				else
					--fallback
					
					love.graphics.draw(sprites.editor.genericevent,pos[1],pos[2],0,1,1,8,8)
				end
				
				if self.multiselect then
					for ii,vv in ipairs(self.multiselect.events) do
						if v == vv then
							love.graphics.draw(sprites.editor.selected,pos[1],pos[2],0,1,1,11,11)
						end
					end
				end
			end
		end
		--redraw selected event on top
		if self.selectedEvent and self.editorBeat <= self.selectedEvent.time then
			local pos = self:getPosition(self.selectedEvent.angle,self.selectedEvent.time)
			if Event.editorDraw[self.selectedEvent.type] then
				Event.editorDraw[self.selectedEvent.type](self.selectedEvent, self.editorBeat, self.editorBeat + self.drawDistance)
			else
				--fallback
				love.graphics.draw(sprites.editor.genericevent,pos[1],pos[2],0,1,1,8,8)
			end
			love.graphics.draw(sprites.editor.selected,pos[1],pos[2],0,1,1,11,11)
		end
		
		
		--draw cursor event
		if self.placeEvent ~= '' and not imgui.GetWantCaptureMouse() then
			love.graphics.setColor(1,1,1,0.5)
			local pos = self:getPosition(self.cursorAngle,self.cursorBeat)
			if Event.editorDraw[self.placeEvent] then
				Event.editorDraw[self.placeEvent]({time = self.cursorBeat, angle = self.cursorAngle, isCursor = true}, self.editorBeat, self.editorBeat + self.drawDistance)
			else
				--fallback
				love.graphics.draw(sprites.editor.genericevent,pos[1],pos[2],0,1,1,8,8)
			end
		end

		--draw timeline slider
		if maininput:down('alt') then
			love.graphics.setLineWidth(2)
			local sectionName = "Start"
			local prevBookmarkBeat = 0
			local nextBookmarkBeat = self.biggestBeat
			
			for i,v in ipairs(self.level.events) do
				if v.type == "bookmark" and v.name ~= '' and v.time < self.editorBeat and v.time > prevBookmarkBeat then
					sectionName = v.name
					prevBookmarkBeat = v.time
				elseif v.type == "bookmark" and v.name ~= '' and v.time > self.editorBeat and v.time < nextBookmarkBeat then
					nextBookmarkBeat = v.time
				end
			end
			
			--prevBookmarkBeat = beat 0, editorBeat - prevBookmarkBeat = curr beat, nextBookmarkBeat - prevBookmarkBeat = biggest beat, practically
			
			--local cAngle = 2*math.pi*self.editorBeat/self.biggestBeat
			--local cX = project.res.cx + (self:beatToRadius(self.editorBeat)-4) * math.sin(cAngle)
			--local cY = project.res.cy - (self:beatToRadius(self.editorBeat)-4) * math.cos(cAngle)
			
			local cAngle = 2*math.pi*(self.editorBeat - prevBookmarkBeat)/(nextBookmarkBeat - prevBookmarkBeat)
			local cX = project.res.cx + (self:beatToRadius(self.editorBeat)-4) * math.sin(cAngle)
			local cY = project.res.cy - (self:beatToRadius(self.editorBeat)-4) * math.cos(cAngle)
			
			local mX = mouse.rx - project.res.cx
			local mY = mouse.ry - project.res.cy
			
			color('black')
			love.graphics.printf(sectionName, project.res.cx-499, project.res.cy-60, 1000, "center")
			
			love.graphics.circle("fill", project.res.cx, project.res.cy, self:beatToRadius(self.editorBeat))
			
			--mouse is on ring
			if not self.altSliderHovered and not self.altSliderHeld and math.abs(math.sqrt(math.pow(mX, 2) + math.pow(mY, 2))-self:beatToRadius(self.editorBeat)+4) < 2 then
				love.graphics.setColor(love.math.colorFromBytes(80, 80, 80))
				love.graphics.arc("line", "open", project.res.cx, project.res.cy, self:beatToRadius(self.editorBeat)-4, 0, 2*math.pi, 100)
				love.graphics.setColor(love.math.colorFromBytes(200, 200, 200))
				love.graphics.arc("line", "open", project.res.cx, project.res.cy, self:beatToRadius(self.editorBeat)-4, -math.pi/2, cAngle-math.pi/2, 100)
				color('white')
			else
				love.graphics.setColor(love.math.colorFromBytes(100, 100, 100))
				love.graphics.arc("line", "open", project.res.cx, project.res.cy, self:beatToRadius(self.editorBeat)-4, 0, 2*math.pi, 100)
				color('white')
				love.graphics.arc("line", "open", project.res.cx, project.res.cy, self:beatToRadius(self.editorBeat)-4, -math.pi/2, cAngle-math.pi/2, 100)
			end
			
			local textWidth = love.graphics.getFont():getWidth(math.floor(self.editorBeat))
			love.graphics.draw(sprites.editor.beaticon, project.res.cx-textWidth/2-5.5, project.res.cy-5)
			color()
			love.graphics.printf(math.floor(self.editorBeat), project.res.cx-18.5, project.res.cy-7, 50, "center")
			
			if self.altSliderHeld then
				love.graphics.setColor(love.math.colorFromBytes(130, 130, 130))
				love.graphics.circle("fill", cX, cY, 3.6)
			elseif self.altSliderHovered then
				love.graphics.setColor(love.math.colorFromBytes(160, 160, 160))
				love.graphics.circle("fill", cX, cY, 4)
			else
				love.graphics.setColor(love.math.colorFromBytes(190, 190, 190))
				love.graphics.circle("fill", cX, cY, 4)
			end
		end

		
		
	else
		
		self.gm:draw()
	end
  love.graphics.setCanvas(shuv.canvas)

  love.graphics.setColor(1, 1, 1, 1)

	self.gm:startOnTopShader()
  self.gm:drawCanv()
	self.gm:endOnTopShader()
	if not self.editMode then
		self.gm:drawExpandedHud()
	end
  if pq ~= "" then
    print(helpers.round(self.cBeat*8,true)/8 .. pq)
  end



end)


return st