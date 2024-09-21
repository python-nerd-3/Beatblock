local st = Gamestate:new('Game')

st:setInit(function(self)
	
  self.gm = em.init("GameManager")
  
  self.gm.noBarelyJudgements = self.noBarelyJudgements  
	mouse:enableGameplay()

  self.canv = love.graphics.newCanvas(project.res.x,project.res.y)

  self.level = LevelManager:loadLevel(cLevel)
  self.gm:resetLevel()
	self.holdEntityDraw = true
	
	self.paused = false
	
	self.pausePosition = {
		x1 = 800,
		x2 = 800,
		y = 100,
		w = 240,
		h = 160,
	}
	self.pauseMenu = em.init('OptionsList')
	self.pauseMenu:addOption('pauseRetry',function()
		self:restartLevel()
	end, 0)
	self.pauseMenu:addOption('pauseQuit',function()
		self:quitLevel()
	end, 20)
	self.pauseMenu:setSelection(1)
end)


function st:leave()
	if cs.vfx.calibration then
		cs.vfx.calibration:onQuit()
	end
	mouse:disableGameplay()
	self.gm:stopLevel()
	em.paused = false
	entities = {}
end

function st:playbackError(message)
	self.errorMessage = message
end

function st:quitLevel()
	self:leave()
	cs = bs.load(returnData.state)
	for k,v in pairs(returnData.vars) do
		cs[k] = v
	end
	cs:init()
end

function st:restartLevel()
	self:leave()
	cs = bs.load('Game')
	cs:init()
	
	cs.rateMod = self.rateMod
	cs.restartOn = self.restartOn
end

function st:goToResults()
	self:leave()
	cs = bs.load('Results')
	--transfer data
	cs.level = self.level
	cs.misses = self.misses
	cs.maxHits = self.maxHits
	cs.barelies = self.barelies
	cs.offset = 0
	for i,v in ipairs(self.tapTiming) do
		cs.offset = cs.offset + v
	end
	if #self.tapTiming ~= 0 then
		cs.offset = math.floor((cs.offset / #self.tapTiming)*1000)/1000
	end
	cs:init()
	cs.rateMod = self.rateMod
end

function st.resume()

end


st:setUpdate(function(self,dt)
	if not self.paused then
		self.gm:update(dt)
		if self.errorMessage then
			self:leave()
			cs = bs.load('Error')
			cs.errorMessage = self.errorMessage
			cs:init()
		end
		if maininput:pressed("pause") then
			self.paused = true
			em.paused = true
			self.gm:stopLevel()
			te.playOne(sounds.pause,"static",'sfx',1)
			flux.to(self.pausePosition,60,{x1 = 300}):ease("outBack")
			flux.to(self.pausePosition,65,{x2 = 300}):ease("outBack")
			self.pauseMenu.allowInput = true
			
			local differenceScore = (math.abs(shuv.pal[0].r - shuv.pal[1].r)+math.abs(shuv.pal[0].g - shuv.pal[1].g)+math.abs(shuv.pal[0].b - shuv.pal[1].b)) / 765
			local brightness = {}
			brightness[0] = (shuv.pal[0].r + shuv.pal[0].g + shuv.pal[0].b) / 765
			brightness[1] = (shuv.pal[1].r + shuv.pal[1].g + shuv.pal[1].b) / 765
			print(differenceScore)
			if differenceScore <= 0.15 then
				local brighter,darker = 0,1
				if brightness[0] < brightness[1] then
					brighter,darker = 1,0
				end
				local change = 128
				flux.to(shuv.pal[brighter],60,{
					r = math.min(shuv.pal[brighter].r + change, 255),
					g = math.min(shuv.pal[brighter].g + change, 255),
					b = math.min(shuv.pal[brighter].b + change, 255),
				})
				flux.to(shuv.pal[darker],60,{
					r = math.max(shuv.pal[darker].r - change, 0),
					g = math.max(shuv.pal[darker].g - change, 0),
					b = math.max(shuv.pal[darker].b - change, 0),
				})
			end
			
		end
	else
		self.pauseMenu:update()
		if maininput:pressed("back") then
			self:quitLevel()
		end
	end

	if cs.misses and cs.barelies then
	if  (maininput:pressed("restart")) or
		(cs.restartOn == 'miss' and cs.misses > 0) or 
		(cs.restartOn == 'barely' and (cs.misses > 0 or cs.barelies > 0)) then
		self:restartLevel()
	end
	end
	
end)



st:setFgDraw(function(self)

  color('white')
  love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
  love.graphics.setCanvas(self.canv)
  
		self.gm:draw()
    --helpers.drawgame()
		
  love.graphics.setCanvas(shuv.canvas)
  love.graphics.setColor(1, 1, 1, 1)
	
	self.gm:startOnTopShader()
  self.gm:drawCanv()
	self.gm:endOnTopShader()
	self.gm:drawExpandedHud()
	
	if self.paused then
		local poly = {
			self.pausePosition.x1 - self.pausePosition.w / 2, self.pausePosition.y,
			self.pausePosition.x1 + self.pausePosition.w / 2, self.pausePosition.y,
			self.pausePosition.x2 + self.pausePosition.w / 2, self.pausePosition.y + self.pausePosition.h,
			self.pausePosition.x2 - self.pausePosition.w / 2, self.pausePosition.y + self.pausePosition.h,
		}
		color(0)
		love.graphics.polygon('fill',poly)
		color(1)
		love.graphics.setLineWidth(2)
		love.graphics.polygon('line',poly)
		love.graphics.setFont(fonts.digitalDisco)
		love.graphics.printf(loc.get('pauseHeader'),self.pausePosition.x1 - 300,self.pausePosition.y+10,300,'center',0,2,2)
		self.pauseMenu:draw(self.pausePosition.x1, 180)
	end
	
  if pq ~= "" then
    print(helpers.round(self.cBeat*8,true)/8 .. pq)
  end

end)


return st