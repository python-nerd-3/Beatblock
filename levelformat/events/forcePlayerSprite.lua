local info = {
	event = 'forcePlayerSprite',
	name = 'Force Player Sprite',
	storeInChart = false,
	description = [[Parameters:
time: Beat to show on
]]
}

--onLoad, onOffset, onBeat

local function onLoad(event)
	if string.lower(string.sub(event.spriteName,-4)) == '.png' then --custom face
		local filename = cLevel..event.spriteName
		if love.filesystem.exists(filename) then
			cs.p.spr[event.spriteName] = love.graphics.newImage(filename)
		else
			cs:playbackError('Could not load custom face sprite "' .. filename .. '"')
		end
	end
end


local function onBeat(event)
	
	if event.spriteName ~= 'none' and event.spriteName ~= '' and cs.p.spr[event.spriteName] == nil then
		cs:playbackError('Player has no face sprite named "' .. event.spriteName .. '"')
		return
	end
	cs.p.forceSprite = event.spriteName
	
	
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.forceplayersprite,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'spriteName', 'Name of sprite, blank for no force, or "none" for no sprite. Can also be a PNG file', {default = ''})
end


return info, onLoad, onOffset, onBeat, editorDraw, editorProperties