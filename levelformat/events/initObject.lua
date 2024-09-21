local info = {
	event = 'initObject',
	name = 'Init Object',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
]]
}

--onLoad, onOffset, onBeat

local function onLoad(event)
	local newObject = nil
	if not pcall(function()
		newObject = em.init(event.objectName,{})
	end) then
		cs:playbackError('Cannot create non-existent object "' .. event.objectName .. '"')
		return
	end
	if event.variableName then
		newObject.isObjectInactive = true
		cs.vfx.objects[event.variableName] = newObject
	end
	
end

local function onBeat(event)

	if event.variableName then
		cs.vfx.objects[event.variableName].isObjectInactive = false
	end
	
end

local function editorProperties(event)
	Event.property(event,'string', 'objectName', 'Name of object', {default = ''})
	Event.property(event,'string', 'variableName', 'If set, obj is inited to vfx.objects[variableName].\nAlso allows the object to be inited at level start', {optional = true, default = ''})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties