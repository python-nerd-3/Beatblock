local info = {
	event = 'tag',
	name = 'Run tag',
	storeInChart = false,
	allowInNoVFX = true,
	description = [[Parameters:
]]
}

--onLoad, onOffset, onBeat
local function onLoad(event)
	if not cs.tags[event.tag] then
		if not pcall(function()
			cs.tags[event.tag] = dpf.loadJson(cLevel .. "tags/" .. event.tag..'.json')
		end) then
			cs:playbackError('Cannot load non-existent tag "' .. cLevel .. "tags/" .. event.tag..'.json' .. '"')
			return
		end
		
		local l = nil
		l, cs.tags[event.tag] = LevelManager:upgradeLevel(cs.level,cs.tags[event.tag],nil,true)
		
		pq = pq .. "      loaded tag " .. event.tag
	end
	for i,v in ipairs(cs.tags[event.tag]) do
		local newevent = helpers.copy(v)
		newevent.time = newevent.time + event.time
		if event.angleOffset then
			newevent.angle = newevent.angle + event.angle
		end
		table.insert(cs.playEvents,newevent)
	end

end


local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.tag,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'tag', 'Name of tag', {default = ''})
	Event.property(event,'bool', 'angleOffset', 'Offset new events by this event\'s angle?', {default = false})
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties