local info = {
	event = 'tutorial_showText',
	name = 'Tutorial Show Text',
	storeInChart = false,
	allowInNoVFX = true,
}


--onLoad, onOffset, onBeat

local function onLoad(event)
	rw:ease(event.time,1,'outExpo',0,cs.vfx.tutorial,'y',10,event.order)
	
end

local function onBeat(event)
	if event.text == '' then
		cs.vfx.tutorial.text = ''
	else
		local locString = event.text
		if event.controls then
			if love.joystick.getJoysticks()[1] and (not savedata.options.game.forceMouseKeyboard) then
				locString = locString .. '_controller'
			else
				locString = locString ..  '_mouse'
			end
		end
		cs.vfx.tutorial.text = loc.get(locString)
	end
end

local function editorProperties(event)
	Event.property(event,'string', 'text', 'loc string to show', {default = ''})
	Event.property(event,'bool', 'controls', 'Append current controller to loc string', {default = false})
end



return info, onLoad, onOffset, onBeat, editorDraw, editorProperties, hitCount