local st = Gamestate:new('Keybinds')

-- my hope is that this code is so bad that either someone will look at it and ban me from ever touching UI again
-- or they'll fix it and i get to claim the credit - bliv


-- 16/08 update:
-- ok i hated it so much i spent all day fixing it instead of finishing it.
-- it's slightly less awful now. - bliv

st:setInit(function(self)
	self.listening = false
	self.hover = false
end)


st:setUpdate(function(self, dt)
--[[
	if string.sub(self.type, 1, 10) == 'controller' then
        if not self.joysticks then
            self.joysticks = love.joystick.getJoysticks()
        end

        if self.listeningJoystick then
            self.activeJoystick = self.activeJoystick or {}

            for k, joystick in ipairs(self.joysticks) do
                local numAxes = joystick:getAxisCount() -- the fact that a joystick is actually just a controller with joysticks on in love2d is dumb. - bliv
                local activeAxes = {}

                for axis = 1, numAxes do
                    local axisValue = joystick:getAxis(axis)
                    if math.abs(axisValue) > 0.2 then
                        table.insert(activeAxes, { axis = axis, value = axisValue })
                    end
                end

                if #activeAxes > 0 then
                    self.activeJoystick = { joystick = joystick, axes = activeAxes }
                else
                    self.activeJoystick[k] = nil
                end
            end
        end
    end]]
		-- I couldn't get the joystick detection to work in a way that I liked, so I've skipped it for now.
		-- I'd like to come back to it later, though. - Bliv
end)

function love.gamepadpressed(joystick, button)
	if string.sub(st.type, 1, 10) == 'controller' then
	 if st.listening then
		te.play(sounds.click,"static",'sfx',0.5)
			if not helpers.hasValue(st.keybinds[st.listening], "button:" .. button) then
				table.insert(st.keybinds[st.listening], "button:" .. button)
	end
			st.listening = nil
	end
	end
	end	

function love.keypressed(key)
	if project.useImgui then -- Fixes bug with imgui breaking after opening the editor menu.
		imgui.KeyPressed(key)
	end
	 if string.sub(st.type, 1, 8) == 'keyboard' then
			if st.listening then
				te.play(sounds.click,"static",'sfx',0.5)
					if not helpers.hasValue(st.keybinds[st.listening], "key:" .. key) then
						table.insert(st.keybinds[st.listening], "key:" .. key)
			end
					st.listening = nil
			end
	end
end

local function newButton(self, bText, x, y, w, h)

	love.graphics.print(bText, x, y)

	love.graphics.rectangle("line", x-2, y-2, w+4, h+4)

	if ((mouse.rx > x-2) and (mouse.rx < x + w + 2)) and ((mouse.ry > y-2) and (mouse.ry < y+h+2)) then
		love.graphics.rectangle("line", x-1, y-1, w+4, h+4)
		if self.hover == false then
			te.play(sounds.hold,"static",'sfx',0.5)
			self.hover = true
		end
		self.endhover = false
		if mouse.pressed == -1 then
			te.play(sounds.click,"static",'sfx',0.5)
			return true
		end
	end

end

st:setBgDraw(function(self)
  color('white')
  love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)

	-- Draw 'Keybinds' at the top of the screen
	color('black')
	love.graphics.print(loc.get('optionsKeybinds' .. helpers.firstupper(self.type)), 25, 15)
end)

--entities are drawn here

st:setFgDraw(function(self)
	color('black')
	self.endhover = true
	local i = 3
	if not self.keybinds then
		print('self.keybinds was nil! type = ' .. self.type)
		for i,v in pairs(savedata.options.bindings) do
			print(i)
		end
	--	self.keybinds = {}
	else
	--	print('self.keybinds was not nil! what\'s going on??')
	--	for i,v in pairs(self.keybinds) do
	--		print(i)
	--	end
		
	end

	-- So...
	-- I designed this code assuming that Lua preserved order for tables like python.
	-- It doesn't. And instead of going back and refactoring how I store the data in the save file, I'm going to hard-code this. I'd apologize but I've been working on this for far too many hours now.

	if not self.keyOrder then
		self.keyOrder = {}
		if self.type == 'keyboardGameplay' then
			-- yay we get to do order
			self.keyOrder["tap1"] = 1
			self.keyOrder["tap"] = 1000
			self.keyOrder["tap2"] = 2
			self.keyOrder["pause"] = 3
			self.keyOrder["restart"] = 4
		elseif self.type == 'keyboardMenu' then
			self.keyOrder["select"] = 1
			self.keyOrder["back"] = 2
			self.keyOrder["menu_up"] = 4
			self.keyOrder["menu_down"] = 5
			self.keyOrder["menu_left"] = 6
			self.keyOrder["menu_right"] = 7
		elseif self.type == 'keyboardEditor' then
			self.keyOrder["play"] = 1
			self.keyOrder["modifier"] = 2
			self.keyOrder["save"] = 3
			self.keyOrder["delete"] = 4
			self.keyOrder["move_up"] = 6
			self.keyOrder["move_down"] = 7
			self.keyOrder["move_left"] = 8
			self.keyOrder["move_right"] = 9
		elseif self.type == 'controllerBinds' then
			self.keyOrder["select"] = 1
			self.keyOrder["back"] = 2
			self.keyOrder["tap"] = 1000 -- This should never happen, but this prevents a crash in case it does.
			self.keyOrder["tap1"] = 3
			self.keyOrder["tap2"] = 4
			self.keyOrder["pause"] = 5
			self.keyOrder["restart"] = 6
			self.keyOrder["menu_up"] = 7
			self.keyOrder["menu_down"] = 8
			self.keyOrder["menu_left"] = 9
			self.keyOrder["menu_right"] = 10
		end
	end

	for action, keys in pairs(self.keybinds) do

		-- draws the name of the thing

		local locAction = loc.get(action)
		local keyOrder = self.keyOrder[action]
		love.graphics.print( string.upper(string.sub(locAction, 1, 1)) .. string.sub(locAction, 2), 25, (25*(self.keyOrder[action]+2)))

		-- iterates over keys - adds a black square around each one
		local dist = 150
		for i2=1, #keys, 1 do
			if keys[i2] then
				local keystring = keys[i2]

				if string.sub(keystring, 1, 6) == 'mouse:' or string.sub(keystring, 1, 4) == 'axis' then -- Does nothing because mouse / joystick is not rebindable.
				else
				if string.sub(keystring, 1, 4) == 'key:' then
					keystring = string.upper(string.sub(keystring, 5, 5)) .. string.sub(keystring, 6)
				end
				if string.sub(keystring, 1, 7) == 'button:' then
					keystring = string.upper(string.sub(keystring, 8, 8)) .. string.sub(keystring, 9)
				end
				
				local fontWidth = fonts.digitalDisco:getWidth(keystring)

				if newButton(self, keystring, dist, 25*(self.keyOrder[action]+2), fontWidth, fonts.digitalDisco:getHeight()) then
					table.remove(keys, i2)
					self.keybinds[action] = keys
				end

				dist = dist + fontWidth + 15
			end
			end
		end
		
		-- Adds the 'add' button to the end
		if #keys < 5 then
			if #keys >= 2 and action == 'tap' then
			else
			local localisedAdd = loc.get("keybindsAddNew")

			if self.listening == action then
				localisedAdd = loc.get("keybindsPressKey")
			end
			
			local fontWidth = fonts.digitalDisco:getWidth(localisedAdd)

			if newButton(self, localisedAdd, dist, 25*(self.keyOrder[action]+2), fontWidth, fonts.digitalDisco:getHeight()) then
				self.listening = action
			end
		end
		end

		i = i + 1
	end

	--[[
	-- Controller Exclusive - Joystick Selection Button
	if string.sub(st.type, 1, 10) == 'controller' then
		-- This is a controller.
		love.graphics.print(string.upper(loc.get("keybindsJoystick")))
		local joyStr = loc.get("keybindsJoystick") .. savedata.options.analogueStick
		if self.listeningJoystick then
			joyStr = loc.get("keybindsAddJoystick")
		end
		if self.activeJoystick then
			--savedata.options.analogueStick = {self.activeJoystick.joystick:getGUID(), self.activeJoystick.axes}
			--joyStr = self.activeJoystick[1].joystick:getName() .. self.activeJoystick.axes
			--self.activeJoystick = nil
			--self.listeningJoystick = false
		end
			if newButton(self, joyStr, 150, 25*i, fonts.digitalDisco:getWidth(joyStr), fonts.digitalDisco:getHeight()) then
				self.listeningJoystick = true
			end
	end
	]]

	-- Back button that loads the previous scene
	local backWidth = fonts.digitalDisco:getWidth(loc.get("back"))
	local buttonPosX = 575 - backWidth
	local buttonPosY = 345 - fonts.digitalDisco:getHeight()

	if newButton(self, loc.get("back"), buttonPosX, buttonPosY, backWidth, fonts.digitalDisco:getHeight()) then
		savedata.options.bindings[self.type] = self.keybinds
		sdfunc.save()
		updateControls() -- reinitialise control manager
		cs = self.ps -- loads previous scene. this is probably a bit of a messy way of doing this, but it makes the illusion that this is just a section of the main menu work.
	end

	local resetWidth = fonts.digitalDisco:getWidth(loc.get("keybindsResetDefault"))
	buttonPosX = buttonPosX - resetWidth - 15

	if newButton(self, loc.get("keybindsResetDefault"), buttonPosX, buttonPosY, resetWidth, fonts.digitalDisco:getHeight()) then
			savedata.options.bindings = {
					keyboardGameplay = {
					tap = {"z", "x"},
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
					tap = {"a", "x"},
					pause = {"start"},
					restart = {}
					}
					}
					-- With this all removed from the defaultSave.json to avoid another bug, this is a bit of a messy fix, but it'll work.

			self.keybinds = savedata.options.bindings[self.type]
			sdfunc.save()
			updateControls() -- reinitialise control manager
		end

	if self.endhover and self.hover == true then
		self.hover = false
	end

end)

return st