local ezanim = {}

function ezanim.new(image,properties)
	local anim = {}
	properties = properties or {}
	
	properties.speed = properties.speed or 60
	
	if type(image) == 'string' then
		anim.image = love.graphics.newImage(image)
	else
		anim.image = image
	end
	
	anim.imagewidth = anim.image:getWidth()
	anim.imageheight = anim.image:getHeight()
	
	anim.width = properties.width or anim.imagewidth
	anim.height = properties.height or anim.imageheight
	
	anim.frames = properties.frames or ( math.floor(anim.imagewidth / anim.width) * math.floor(anim.imageheight / anim.height) )
	
	anim.quads = {}
	local numquads = 0
	
	for y = 0, math.floor(anim.imageheight / anim.height) - 1 do
		for x = 0, math.floor(anim.imagewidth / anim.width)  - 1 do
			local quad = love.graphics.newQuad(x*anim.width,y*anim.height,anim.width,anim.height,anim.imagewidth,anim.imageheight)
			if numquads < anim.frames then
				anim.quads[numquads] = quad
				numquads = numquads + 1
			end
		end
	end
	
	anim.states = {}
	
	function anim:addState(name,frames,speed,loop)
		local newstate = {}
		newstate.frames = frames
		newstate.speed = speed or properties.speed
		newstate.loop = loop
		if newstate.loop == nil then
			newstate.loop = true
		end
		self.states[name] = newstate
		self.mostrecentstate = name
	end
	
	local allframes = {}
	for i=0,anim.frames -1 do
		table.insert(allframes,i)
	end
	anim:addState('all',allframes,properties.speed,properties.loop)
	
	function anim:draw(frame,x,y,r,sx,sy,ox,oy,kx,ky)
		love.graphics.draw(self.image,self.quads[frame],x,y,r,sx,sy,ox,oy,kx,ky) --crash!
	end
	
	function anim:drawState(state,frame,x,y,r,sx,sy,ox,oy,kx,ky)
		self:draw(self.states[state].frames[frame+1],x,y,r,sx,sy,ox,oy,kx,ky)
	end
	
	
	function anim:instance(state)
		return ezanim.instance(self,state)
	end
	
	return anim
	
end

function ezanim.newjson(image,jsonFilename)
	
	if not jsonFilename then
		jsonFilename = image .. '.json'
		image = image .. '.png'
	end
	
	local templateInfo = json.decode(love.filesystem.read(jsonFilename))
	local newTemplate = ez.new(image,{
		speed = templateInfo.fps,
		width = templateInfo.width,
		height = templateInfo.height,
		frames = templateInfo.frames
	})
	if templateInfo.states then
		for i,v in ipairs(templateInfo.states) do
			newTemplate:addState(v.name,v.frames,v.fps,v.loop)
			
		end
		
	end
	return newTemplate
	
end

function ezanim.instance(anim,state)
	
	local inst = {}
	inst.anim = anim
	inst.state = state or anim.mostrecentstate
	inst.frame = 0
	inst.timer = 0
	
	function inst:play(state,frame)
		self.state = state
		self.frame = frame or 0
		self.timer = 0
	end
	
	function inst:update(dt,speedOverride)
		local state = self.anim.states[self.state]
		local speed = speedOverride or state.speed
		if speed == 0 then
			return
		end
		
		self.timer = self.timer + dt
		
		while self.timer >= (60/speed) do
			self.frame = self.frame + 1
			self.timer = self.timer - (60/speed)
		end
		
		if self.frame >= #state.frames then
			if state.loop then
				self.frame = self.frame % #state.frames
			else
				self.frame = #state.frames - 1
			end
		end
		
	end
	
	function inst:draw(x,y,r,sx,sy,ox,oy,kx,ky)
		self.anim:drawState(self.state,self.frame,x,y,r,sx,sy,ox,oy,kx,ky)
	end
	
	function inst:drawFrame(frame,x,y,r,sx,sy,ox,oy,kx,ky)
		self.anim:draw(frame,x,y,r,sx,sy,ox,oy,kx,ky)
	end
	
	return inst
	
end




return ezanim