local info = {
	event = 'ease',
	name = 'Ease',
	storeInChart = false,
	description = [[Parameters:
time: Beat to start
var: Variable to ease (must be a child of cs)
start (Optional): Starting value
value: End value
duration (Optional): length of ease
ease (Optional): ease to use
]]
}


--onLoad, onOffset, onBeat

local function onLoad(event)
	local duration = event.duration or 0
	local ease = event.ease or 'linear'
	
	local repeats = event.repeats or 0
	local repeatDelay = event.repeatDelay or 1
	
	local var = cs
	local varSplit = {}
	
	for v in string.gmatch(event.var,"([^.]+)") do
		table.insert(varSplit,v)
	end
	if #varSplit == 0 then
		cs:playbackError('Error while easing: No variable to ease was provided.')
		return
	end
	for i,v in ipairs(varSplit) do
		if var[v] then
			if type(var[v]) ~= 'number' and type(var[v]) ~= 'table' then
				cs:playbackError('Error while easing: tried to overwrite non-number variable or function "' .. v .. '"')
			else
				if i ~= #varSplit then
					var = var[v]
				end
			end
		else
			--[[
			if project.strictLoading then
				error("Couldnt find key '" .. v .. "' in cs."..event.var)
			else
				print("EASE ERROR: Couldnt find key '" .. v .. "' in cs."..event.var)
				return
			end
			]]
			cs:playbackError('Error while easing: Couldnt find key "' .. v .. '" in cs.'..event.var)
			return
		end
	end
	
	local param = varSplit[#varSplit]
	
	for i=0,repeats do
		rw:ease(event.time+(i*repeatDelay),duration,ease,event.value,var,param,event.start,event.order)
	end
	
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.ease,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'var', 'Variable to ease (must be a child of cs)', {default = ''})
	Event.property(event,'decimal', 'start', 'Starting value', {step = 0.01, optional = true, default = 0})
	Event.property(event,'decimal', 'value', 'Ending value', {step = 0.01, default = 0})
	Event.property(event,'decimal', 'duration', 'Length of ease', {step = cs:getBeatStep(), optional = true, default = 0})
	Event.property(event,'enum', 'ease', 'Ease function to use', {enum = 'ease', optional = true, default = 'linear'})
	Event.property(event,'int', 'repeats', 'Times to repeat', {optional = true, default = 0})
	Event.property(event,'decimal','repeatDelay', 'Beats between repeats', {step = cs:getBeatStep(),optional = true, default = 1})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties