Calibration = class('Calibration',Entity)

function Calibration:initialize(params)
  
  self.layer = 10 -- lower layers draw first
  self.upLayer = 99 --lower upLayer updates first
  self.x = 0
  self.y = 0
  self.text = ''
	
	
  Entity.initialize(self,params)
	
	mouse:disableGameplay()
	
	self.oldOffset = savedata.options.game.inputOffset
	savedata.options.game.inputOffset = 0
	
	self.newOffset = 0
	self.isFinished = false
	
	cs.forceTimingWindow = 500
	cs.forceSpamWindow = 0

end

function Calibration:update(dt)
  prof.push("Calibration update")
	if self.isFinished then
		self.optionsList:update()
	end
  prof.pop("Calibration update")
end

function Calibration:finish()
	print('calibration finished')
	self.isFinished = true
	self.optionsList = em.init('OptionsList',{allowInput = true})
	self.optionsList:addText('calibration_3',-17,{self.oldOffset, self.newOffset})
	self.optionsList:addOption('calibration_4',function()
		savedata.options.game.inputOffset = self.newOffset
		self:exitLevel()
	end, 17, {self.newOffset})
	self.optionsList:addOption('calibration_5',function() 
		savedata.options.game.inputOffset = self.oldOffset
		self:exitLevel()
	end, 34, {self.oldOffset})
	self.optionsList:setSelection(1)
end

function Calibration:onQuit()
	print('quit out of calibration early')
	savedata.options.game.inputOffset = self.oldOffset
end

function Calibration:exitLevel()
	sdfunc.save()
	cs.gm:stopLevel()
	entities = {}
	cs = bs.load(returnData.state)
	for k,v in pairs(returnData.vars) do
		cs[k] = v
	end
	cs:init()
end

function Calibration:draw()
  prof.push("Calibration draw")
	--just for this, we're gonna increase line height.
	
	love.graphics.setFont(fonts.main)
	
	color()
	love.graphics.rectangle('fill',self.x+10,self.y+10,self.x+130,self.y+340)
  color(1)
	love.graphics.rectangle('line',self.x+10,self.y+10,self.x+130,self.y+340)
	local avg = 0
	for i,v in ipairs(cs.tapTiming) do
		avg = avg + v
		local x = self.x + 24
		if i % 2 == 0 then
			x = x + 60
		end
		local y = self.y + 12 + math.floor((i-1)/2)*8
		local txt = math.floor(v * 1000) / 1000
		love.graphics.print(txt,x,y)
	end
	if #cs.tapTiming ~= 0 then
		self.newOffset = math.floor((avg / #cs.tapTiming) + 0.5) * -1
		avg = math.floor((avg / #cs.tapTiming)*1000)/1000
		love.graphics.print(loc.get('averageOffset',{avg}),self.x + 14, self.y+300)
	end
	
	if self.isFinished then
		love.graphics.setFont(fonts.digitalDisco)
		self.optionsList:draw(self.x + project.res.cx, self.y + project.res.cy + 60)
	end
	
  prof.pop("Calibration draw")
end

return Calibration