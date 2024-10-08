function love.conf(t)
	if love.filesystem.getInfo('project.lua') then
		project = require('project')
	else
		project = require('projects.debug')
	end
	project.res.cx = project.res.x / 2
	project.res.cy = project.res.y / 2
	t.externalstorage = true

	
	t.identity = 'beatblock'
	t.appendidentity = true
	project.saveLoc = 'savedata/main.sav'
	project.defaultSaveLoc = 'data/defaultsave.json'
	
	t.window.usedpiscale = false
	if not project.release then
		t.console = true
	end

	t.window.width = project.res.x
	t.window.height = project.res.y
	t.window.vsync = 0

  
end
