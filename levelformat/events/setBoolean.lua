local info = {
	event = 'setBoolean',
	name = 'Set Boolean',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
]]
}

--onLoad, onOffset, onBeat

local function onBeat(event)
	local var = cs
	local varSplit = {}
	
	for v in string.gmatch(event.var,"([^.]+)") do
		table.insert(varSplit,v)
	end
	
	for i,v in ipairs(varSplit) do
		if type(var[v]) ~= 'boolean' and type(var[v]) ~= 'table' then -- panic and exit function
			cs:playbackError('Error while setting boolean: tried to overwrite non-boolean variable or function "' .. v .. '"')
			return
		end

		if i == #varSplit then
			var[v] = event.enable
			return
		end
		if var[v] ~= nil then
			var = var[v]
		else
			if project.strictLoading then
				error("Couldnt find key '" .. v .. "' in cs."..event.var)
			else
				print("Couldnt find key '" .. v .. "' in cs."..event.var)
				return
			end
		end
	end
	
	
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.setboolean,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'var', 'Variable to set (must be a child of cs)', {default = ''})
	Event.property(event,'bool', 'enable', 'The value', {default = true})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties