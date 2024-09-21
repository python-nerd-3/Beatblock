OptionsList = class('OptionsList',Entity)

function OptionsList:initialize(params)
  
	self.skipRender = true
	self.skipUpdate = true
  self.layer = 0 -- lower layers draw first
  self.upLayer = 0 --lower upLayer updates first
	
  self.x = 0
  self.y = 0
	self.allowInput = true
	
	self.selection = 1
	self.selectionY = 0
	self.width = 0
	self.ease = nil
	
	self.maxWidth = 0
	self.maxY = 0
	
	self.options = {
		main = {}
	}
	self.submenu = 'main'
  
  Entity.initialize(self,params)

end
function OptionsList:defineSubmenu(name)
	name = name or 'main'
	self.options[name] = self.options[name] or {}
	self.submenu = name
end

function OptionsList:setSelection(s)
	self.selection = s
	self.selectionY = self.options[self.submenu][s].y
	self.width = self.options[self.submenu][s].width
	if self.ease then 
		self.ease:stop()
	end
	self.ease = nil
end

function OptionsList:setSubmenu(name)
	self.submenu = name
	self:setSelection(1)
end

function OptionsList:calculateWidth(option,width)
	width = width or fonts.digitalDisco:getWidth(option.text)
	
	self.maxWidth = math.max(self.maxWidth, width)
	self.maxY = math.max(self.maxY, option.y)
	return width
end

function OptionsList:addText(text,y,locvars)
	local option = {}
	option.type = 'text'
	option.text = loc.get(text,locvars)
	option.textRaw = text
	option.y = y
	option.width = fonts.digitalDisco:getWidth(option.text)
	
	table.insert(self.options[self.submenu],option)
end

function OptionsList:addOption(text,func,y,locvars)
	local option = {}
	option.type = 'option'
	option.text = loc.get(text,locvars)
	option.textRaw = text
	if type(func) == 'string' then
		option.func = function() self:setSubmenu(func) end
	else
		option.func = func
	end
	option.y = y
	
	
	option.width = self:calculateWidth(option)
	
	table.insert(self.options[self.submenu],option)
end

function OptionsList:addBoolean(text,object,value,y,func)
	local option = {}
	option.type = 'boolean'
	if #text == 3 then
		option.textTrue = loc.get(text[1])..loc.get(text[2])
		option.textFalse = loc.get(text[1])..loc.get(text[3])
	elseif #text == 2 then
		option.textTrue = loc.get(text[1])
		option.textFalse = loc.get(text[2])
	end
	option.object = object
	option.value = value
	option.y = y
	option.func = func
	
	local width = math.max(fonts.digitalDisco:getWidth(option.textTrue),fonts.digitalDisco:getWidth(option.textFalse))
	option.width = self:calculateWidth(option,width)
	table.insert(self.options[self.submenu],option)
end

function OptionsList:numberSelectedText(text)
	return '[-]  ' .. text .. '  [+]' --i'll come up with something more elegant if i need to, tbh
end

function OptionsList:leftRightSelectedText(text)
	return '[<]  ' .. text .. '  [>]' 
end

function OptionsList:addNumber(text,object,value,y,increment,clamp,func)
	local option = {}
	
	option.type = 'number'
	option.text = text
	option.object = object
	option.value = value
	option.y = y
	option.increment = increment or 1
	option.clamp = clamp
	option.func = func
	
	local width = fonts.digitalDisco:getWidth(self:numberSelectedText(loc.get(text,{object[value]})))
	option.width = self:calculateWidth(option,width)
	table.insert(self.options[self.submenu],option)
end


function OptionsList:addCustom(text,y,extraWidth)
	extraWidth = extraWidth or 0
	local option = {}
	option.type = 'custom'
	option.y = y
	
	local width = fonts.digitalDisco:getWidth(loc.get(text))+extraWidth
	option.width = self:calculateWidth(option,width)
	
	option.onInput = function() end
	option.getText = function() return 'Custom Option' end
	
	table.insert(self.options[self.submenu],option)
	return option
end

function OptionsList:addEnum(textStart,textValues,object,value,y,func) --listen technically not an enum. but. 
	local option = {}
	
	option.type = 'enum'
	option.textStart = textStart
	
	option.displayTextValues = {}
	if type(textValues[1]) == 'string' then
		option.textValues = textValues
		for i,v in ipairs(textValues) do
			option.displayTextValues[v] = v
		end
	else
		option.textValues = {}
		for i,v in ipairs(textValues) do
			table.insert(option.textValues,v[1])
			option.displayTextValues[v[1]] = v[2]
		end
	end
	option.object = object
	option.value = value
	
	option.y = y
	option.func = func
	
	
	local width = 0
	
	for k,v in pairs(option.displayTextValues) do
		local realText = loc.get(v)
		if option.textStart then
			realText = loc.get(option.textStart,{realText})
		end
		width = math.max(fonts.digitalDisco:getWidth(self:leftRightSelectedText(realText)),width)
	end
	
	option.width = self:calculateWidth(option,width)
	table.insert(self.options[self.submenu],option)
end

function OptionsList:update(dt)
  prof.push("OptionsList update")
	
	if not self.allowInput then
		return
	end
	
	local moved = false
	
	local oldSelection = self.selection
		
	if maininput:pressed("menu_up") then
		self.selection = self.selection - 1
		moved = true
	end
	if maininput:pressed("menu_down") then
		self.selection = self.selection + 1
		moved = true
	end
	
	if mouse.sy and mouse.sy ~= 0 then
		self.selection = self.selection - helpers.clamp(mouse.sy,-1,1)
		moved = true
	end
	
	local clickedOnItem = false
	local clickX = 0
	local mouseMoved = false
	if mouse.rx >= self.x - self.maxWidth*0.5 - 2 and mouse.rx <= self.x + self.maxWidth*0.5 + 2 then
		for i,v in ipairs(self.options[self.submenu]) do
			if mouse.ry >= self.y + v.y - 2 and mouse.ry < self.y + v.y + 16 and (not clickedOnItem) then
				self.selection = i
				mouseMoved = true
				if mouse.pressed == 1 then
					clickedOnItem = true
					clickX = ((mouse.rx - self.x) / self.options[self.submenu][self.selection].width) * 2
				end
			end
		end
	end
	self.selection = (self.selection - 1) % #self.options[self.submenu] + 1
		
	if (moved or mouseMoved) and (not clickedOnItem) and self.selection ~= oldSelection then
		
		te.play(sounds.click,"static",'sfx',0.5)
		--print(self.submenu,self.selection)
			self.ease = flux.to(self,30,
			{
				selectionY = self.options[self.submenu][self.selection].y,
				width = self.options[self.submenu][self.selection].width
			}
		):ease("outExpo")
		
	end
	
	local ranFunction = false
	local option = self.options[self.submenu][self.selection]
	if maininput:pressed('accept') or clickedOnItem then
		if option.type == 'option' then
			te.play(sounds.hold,"static",'sfx',0.5)
			option.func()
			ranFunction = true
		elseif option.type == 'boolean' then
			te.play(sounds.hold,"static",'sfx',0.5)
			option.object[option.value] = not option.object[option.value]
			if option.func then
				option.func()
			end
		end
	end
	
	if option.type == 'boolean' then
		if maininput:pressed('menu_left') or maininput:pressed('menu_right') then
			te.play(sounds.hold,"static",'sfx',0.5)
			option.object[option.value] = not option.object[option.value]
			if option.func then
				option.func()
			end
		end
	end

	if option.type == 'number' then
		local changed = false
		if maininput:pressed('menu_left') or clickX <= -0.25 then
			option.object[option.value] = option.object[option.value] - option.increment
			changed = true
		elseif maininput:pressed('menu_right') or clickX >= 0.25  then
			option.object[option.value] = option.object[option.value] + option.increment
			changed = true
		end
		if changed then
			if option.clamp then
				option.object[option.value] = helpers.clamp(option.object[option.value],option.clamp[1],option.clamp[2])
			end
			te.play(sounds.hold,"static",'sfx',0.5)
			option.width = fonts.digitalDisco:getWidth(self:numberSelectedText(loc.get(option.text,{option.object[option.value]})))
			self.width = option.width
			if option.func then
				option.func()
			end
		end
	end
	
	if option.type == 'custom' then
		local optionX = 0 
		local changed = false
		
		if maininput:pressed('menu_left') or clickX <= -0.25 then
			optionX = -1
			changed = true
		elseif maininput:pressed('menu_right') or clickX >= 0.25  then
			optionX = 1
			changed = true
		end
		if changed or maininput:pressed('accept') or clickedOnItem then
			option:onInput(optionX)
		end
	end
	if option.type == 'enum' then
		local enumInt = 1
		for i,v in ipairs(option.textValues) do
			if v == option.object[option.value] then
				enumInt = i
			end
		end
		
		local changed = false
		if maininput:pressed('menu_left') or clickX <= -0.25 then
			enumInt = enumInt - 1
			changed = true
		elseif maininput:pressed('menu_right') or clickX >= 0.25  then
			enumInt = enumInt + 1
			changed = true
		end
		enumInt = ((enumInt - 1) % #option.textValues) + 1
		if changed then
			te.play(sounds.hold,"static",'sfx',0.5)
			option.object[option.value] = option.textValues[enumInt]
			if option.func then
				option.func()
			end
		end
	end
	
  prof.pop("OptionsList update")
	return ranFunction
end

function OptionsList:draw(x,y)
  prof.push("OptionsList draw")
	
	self.x = x or self.x
	self.y = y or self.y
	
  color(1)
	
	for i,v in ipairs(self.options[self.submenu]) do
		local x = self.x - math.floor(v.width / 2)
		local y = self.y+ v.y
		if v.type == 'option' or v.type == 'text' then
			love.graphics.print(v.text,x,y)
		elseif v.type == 'boolean' then
			local text = v.textFalse
			if v.object[v.value] then
				text = v.textTrue
			end
			love.graphics.print(text,x,y)
		elseif v.type == 'number' then
			love.graphics.print(self:numberSelectedText(loc.get(v.text,{v.object[v.value]})),x,y)
		elseif v.type == 'custom' then
			local text = v:getText()
			love.graphics.print(text,self.x - math.floor(fonts.digitalDisco:getWidth(text)/2),y)
		elseif v.type == 'enum' then
			
			local realText = loc.get(v.displayTextValues[v.object[v.value]] or 'ENUM ERROR!')
			if v.textStart then
				realText = loc.get(v.textStart,{realText})
			end
			realText = self:leftRightSelectedText(realText)
			love.graphics.print(realText,self.x - math.floor(fonts.digitalDisco:getWidth(realText)/2),y)
		end
	end
	
	
	love.graphics.setLineWidth(1)
	love.graphics.rectangle('line',self.x - (self.width/2) - 2, self.y + self.selectionY,self.width + 4, 16)
	
	
  prof.pop("OptionsList draw")
end

return OptionsList