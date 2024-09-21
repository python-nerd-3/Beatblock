local info = {
	event = 'template',
	name = '_TEMPLATE',
	storeInChart = false,
	description = [[Parameters:
time: Beat
]]
}

--onLoad, onOffset, onBeat
local function onLoad(event)
	print('template event called')
end


return info, onLoad, onOffset, onBeat