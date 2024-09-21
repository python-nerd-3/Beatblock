local shuv = {
  scale = 5,
  internal_scale = 1,
  update = true,
  xoffset = 0,
  yoffset = 0,
  screensize_canvases = {},
	paldefault = {},
	pal = {},
	showBadColors = false,
	usePalette = true,
  fullscreen = false,
  windowed_scale = 3,
  windowed_xoffset = 0,
	displayMode = 'windowed'
}

function shuv.makeCanvas()
  local c = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)

  local index = #shuv.screensize_canvases + 1
  local canvas = {
    canvas = c,
    index = index
  }
  shuv.screensize_canvases[index] = canvas
  return canvas
end

function shuv.deleteCanvas(canvas) 
  canvas.canvas:release()
  table.remove(shuv.screensize_canvases, canvas.index)
end

function shuv.init(project)
  shuv.canvas = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)
  shuv.canvasShaded = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)
  shuv.lastFrame = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)
  shuv.scale = project.res.s
  if project.intScale then
		shuv.internal_rescale(project.intScale)
	end
	
	shuv.paldefault[0] = {r=255,g=255,b=255}
	shuv.paldefault[1] = {r=0,  g=0,  b=0  }
	shuv.paldefault[2] = {r=127,g=127,b=127}
	shuv.paldefault[3] = {r=191,g=191,b=191}
	shuv.paldefault[4] = {r=0,g=0,b=0}
	shuv.paldefault[5] = {r=0,g=0,b=0}
	shuv.paldefault[6] = {r=0,g=0,b=0}
	shuv.paldefault[7] = {r=0,g=0,b=0}
	shuv.pal = helpers.copy(shuv.paldefault)
	
end

function shuv.internal_rescale(scale)
  shuv.internal_scale = scale
  shuv.canvas = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)
  shuv.lastFrame = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)
  for _, v in ipairs(shuv.screensize_canvases) do
    v.canvas = love.graphics.newCanvas(project.res.x * shuv.internal_scale, project.res.y * shuv.internal_scale)
  end
end

function shuv.hackyfix()
  local olddraw = love.graphics.draw
  love.graphics.draw = function(...)
    local arg = {...}
    if type(arg[2]) == 'number' then
      arg[2] = math.floor(arg[2]+0.5)
      arg[3] = math.floor(arg[3]+0.5)
    else
      if arg[2] then
        arg[3] = math.floor(arg[3]+0.5)
        arg[4] = math.floor(arg[4]+0.5)
      else
        arg[2] = 0
        arg[3] = 0
      end
    end
    olddraw(unpack(arg))
  end
end

function shuv.do_autoscaled(func)
  love.graphics.push()
  love.graphics.scale(shuv.internal_scale, shuv.internal_scale)
  func()
  love.graphics.pop()
end

function shuv.check()
  if not ismobile then
		--[[
    if maininput:pressed("k3") then
      shuv.internal_rescale(shuv.internal_scale - 1)
    end
    if maininput:pressed("k4") then
      shuv.internal_rescale(shuv.internal_scale + 1)
    end
		]]--
    if maininput:pressed("f5") and shuv.displayMode == "windowed" then
      shuv.windowed_scale = shuv.windowed_scale + 1
      if shuv.windowed_scale > 5 then
        shuv.windowed_scale = 1
      end
			savedata.options.graphics.windowScale = shuv.windowed_scale
      shuv.update = true
    end
    if maininput:pressed("toggle_fullscreen") then

      --shuv.fullscreen = not shuv.fullscreen
      if shuv.displayMode == "windowed" then
				shuv.displayMode = "fullscreen"
			elseif shuv.displayMode == "fullscreen" then
				shuv.displayMode = "borderless"
			else
				shuv.displayMode = "windowed"
			end
      shuv.update = true
			savedata.options.graphics.displayMode = shuv.displayMode
    end
  end

  if shuv.update then
    
    shuv.update = false
    if ismobile or project.fullscreen or shuv.displayMode ~= "windowed" then
      --shuv.windowed_xoffset = shuv.xoffset
      
      love.window.setMode(0,0)

			if shuv.displayMode == "fullscreen" then
      	love.window.setFullscreen(true, 'exclusive')
			else
				love.window.setFullscreen(true, 'desktop')
			end
      shuv.scale = love.graphics.getHeight() / project.res.y
      shuv.xoffset = love.graphics.getWidth()/2 - (project.res.x* shuv.scale) / 2
    else
			shuv.scale = savedata.options.graphics.windowScale
			--shuv.xoffset = shuv.windowed_xoffset
			shuv.xoffset = 0 -- I can't see any situation where base xoffset WOULDN'T be 0, however I did see a bunch of bugs arise from this, so... it's 0 now. Sue me. - Bliv
			love.window.setFullscreen(false)
      love.window.setMode(project.res.x*shuv.scale, project.res.y*shuv.scale, {vsync = love.window.getVSync()})
    end
  end
end

function shuv.updatepal()
	local newpal = {}
	for c=0,7 do
		local col = shuv.pal[c]
		local coltable = {}
		table.insert(coltable,col.r/255)
		table.insert(coltable,col.g/255)
		table.insert(coltable,col.b/255)
		table.insert(coltable,1)
		
		table.insert(newpal,coltable)
	end
  shaders.palshader:send('newcolors',unpack(newpal))
	if shuv.showBadColors then
		shaders.palshader:send('showBadColors', 1)
	else
		shaders.palshader:send('showBadColors', 0)
	end
end

function shuv.resetPal()
	shuv.pal = helpers.copy(shuv.paldefault)
end


function shuv.start()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setCanvas(shuv.canvas)
  love.graphics.setBlendMode("alpha")
end


function shuv.finish()
	
	shuv.updatepal()
	
	if shuv.usePalette then
		love.graphics.setShader(shaders.palshader)
	else
		love.graphics.setShader()
	end
	
  love.graphics.setCanvas(shuv.canvasShaded)
	love.graphics.draw(shuv.canvas)
	
  love.graphics.setCanvas()
	love.graphics.setShader()
  love.graphics.draw(shuv.canvasShaded,shuv.xoffset,shuv.yoffset,0,shuv.scale / shuv.internal_scale,shuv.scale / shuv.internal_scale)
	tinput = ""
  
  love.graphics.setCanvas(shuv.lastFrame)
  love.graphics.draw(shuv.canvas,0,0)
  love.graphics.setCanvas()
	
end

return shuv