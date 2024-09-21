local info = {
	event = 'deco',
	name = 'Decoration',
	storeInChart = false,
	description = [[Parameters:
]]
}

--onLoad, onOffset, onBeat
local function onLoad(event)
	--preload sprites
	local template = nil
	local animation = nil
	local frame = nil
	local speed = nil
	if (event.sprite ~= nil) and (event.sprite ~= '') then
		
		
		template = event.sprite:match("(%w+)[!@#]")
		animation = event.sprite:match("!(%w+)")
		frame = event.sprite:match("#(%w+)")
		speed = event.sprite:match("@(%w+)")
		
		if speed and (not animation) then 
			animation = 'all'
		end
		if not pcall(function()
			if not template then
				if not cs.vfx.decoSprites[event.sprite] then
					cs.vfx.decoSprites[event.sprite] = love.graphics.newImage(cLevel..event.sprite)
				end
			else
				cs.vfx.decoTemplates[template] = ez.newjson(cLevel..template)
				
			end
		end) then
			local filename = cLevel..event.sprite
			if template then
				filename = cLevel..template .. '.json'
			end
			cs:playbackError('Could not load deco file "' .. filename .. '"')
			return
		end
		
	end
	
	
	local easableproperties = {'x','y','r','sx','sy','ox','oy','kx','ky'}
	local otherproperties = {'sprite', 'drawLayer', 'drawOrder', 'recolor', 'outline', 'effectCanvas', 'effectCanvasRaw', 'hide'}
	
	local duration = event.duration or 0
	local ease = event.ease or 'linear'
	
	
	if not cs.vfx.deco[event.id] then
		cs.vfx.deco[event.id] = em.init('Deco',{})
		duration = 0
	end
	


	rw:func(event.time,function() 
		for i,v in ipairs(otherproperties) do
			if event[v] ~= nil then
				cs.vfx.deco[event.id][v] = event[v]
			end
		end
		cs.vfx.deco[event.id]:updateSprite()
	end)
	local kvtable = {}
	for i,v in ipairs(easableproperties) do
		kvtable[v] = event[v]
	end
	if kvtable ~= {} then
		rw:ease(event.time,duration,ease,kvtable,cs.vfx.deco[event.id],nil,nil,event.order)
	end
	--anim
	if event.sprite ~= nil and (event.sprite ~= '') then
		rw:func(event.time,function() 
			if template then
				cs.vfx.deco[event.id].anim = cs.vfx.decoTemplates[template]:instance()
				if animation then
					cs.vfx.deco[event.id].anim:play(animation,tonumber(frame))
					cs.vfx.deco[event.id].animSpeed = tonumber(speed)
					cs.vfx.deco[event.id].animFrame = nil
				else
					cs.vfx.deco[event.id].animSpeed = nil
					cs.vfx.deco[event.id].animFrame = tonumber(frame)
				
				end
			else
				cs.vfx.deco[event.id].anim = nil
				cs.vfx.deco[event.id].animSpeed = nil
				cs.vfx.deco[event.id].animFrame = nil
			end
		end)
	end
	
	
	
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.deco,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'id', 'Unique ID for the deco (if this ID does not exist, a deco will be created)', {default = ''})
	Event.property(event,'string', 'sprite', 'File name of sprite', {optional = true, default = ''})
	
	Event.property(event,'decimal','x', 'X position', {step = 1, optional = true, default = project.res.cx})
	Event.property(event,'decimal','y', 'Y position', {step = 1, optional = true, default = project.res.cy})
	
	Event.property(event,'decimal','r', 'Rotation', {step = 1, optional = true, default = 0})
	
	Event.property(event,'decimal','sx', 'X scale', {step = 0.1, optional = true, default = 1})
	Event.property(event,'decimal','sy', 'Y scale', {step = 0.1, optional = true, default = 1})
	
	Event.property(event,'decimal','ox', 'X offset', {step = 1, optional = true, default = 0})
	Event.property(event,'decimal','oy', 'Y offset', {step = 1, optional = true, default = 0})
	
	Event.property(event,'decimal','kx', 'X skew', {step = 1, optional = true, default = 0})
	Event.property(event,'decimal','ky', 'Y skew', {step = 1, optional = true, default = 0})
	
	Event.property(event,'enum',   'drawLayer', 'Layer to render on', {enum = 'layer', optional = true, default = 'fg'})
	Event.property(event,'int',    'drawOrder', 'Order in layer, lower is drawn first', {optional = true, default = 0})
	
	Event.property(event,'colorIndex', 'recolor', 'Color to replace all non-alpha with (-1 to use original colors)', {optional = true, noColor = true, default = -1})
	
	Event.property(event,'bool', 'outline', 'Enable global outlining for this deco', {optional = true, default = false})
	
	Event.property(event,'bool', 'hide', 'Hide the deco', {optional = true, default = false})
	
	Event.property(event,'bool', 'effectCanvas', 'Draw this deco on the effect canvas instead of the regular canvas', {optional = true, default = false})
	
	if event.effectCanvas then
		Event.property(event,'bool', 'effectCanvasRaw', 'Draw to the effect canvas without recoloring?', {default = false})
	else
		event.effectCanvasRaw = nil
	end
	
	
	Event.property(event,'decimal', 'duration', 'Length of ease (IGNORED IF DECO IS JUST BEING CREATED)', {step = cs:getBeatStep(), optional = true, default = 0})
	Event.property(event,'enum', 'ease', 'Ease function to use (IGNORED IF DECO IS JUST BEING CREATED)', {enum = 'ease', optional = true, default = 'linear'})
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties