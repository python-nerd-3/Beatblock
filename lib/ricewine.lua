local ricewine = {
	tweens = {},
	startBeat = 0,
	bpm = 100,
	functween = {x=0},
	queuedtweens = {}
}
ricewine.flux = dofile("lib/flux/flux.lua")
if not ricewine.flux then
	error('flux.lua not found!')
end

function ricewine:easenow(start,length,easefn,val,obj,param,startVal)

	local kvtable = {}
	local startkvtable = {}
	if type(val) == 'table' then
		kvtable = val
		startkvtable = startVal
	else
		kvtable[param] = val
		startkvtable[param] = startVal
	end

	if start < self.startBeat or length == 0 then
		self:to(obj, 0, kvtable)
	else
		if not startVal then
			self:to(obj, length, kvtable):ease(easefn)
		else
			
			self:to(obj, 0, startkvtable)
			self:to(obj, length, kvtable):ease(easefn)
		end
	end
end

function ricewine:funcnow(start,dofunc) --for backwards compat
	dofunc()
	--[[
	if start < self.startBeat then
		dofunc()
	else
		start = (start - self.startBeat) 
		table.insert(self.tweens,self.flux.to(self.functween, 0, {x=0}):delay(start):onstart(dofunc))
	end
	]]--
end

function ricewine:ease(start,length,easefn,val,obj,param,startparam,order)
	table.insert(self.queuedtweens,{time = start, order = order, func = function() self:easenow(start,length,easefn,val,obj,param,startparam) end})
end

function ricewine:func(start,dofunc,order)
	table.insert(self.queuedtweens,{time = start, order = order, func = dofunc})
end

function ricewine:stopAll()
	local deleted = 0
	for i=1, #self.tweens do
		v = self.tweens[i-deleted]
		if v._oncomplete then v._oncomplete = nil end
		if v._onstart then v._onstart = nil end
		v:stop()
		table.remove(self.tweens,i-deleted)
		deleted = deleted + 1
	end
	self.queuedtweens = {}
	if deleted ~= 0 then
		print('removed '..deleted..' tweens')
	end
end

function ricewine:update(beat)
	local deltaBeat = 0
	if self.beat then
		deltaBeat = beat - self.beat
	end
	self.beat = beat
	
	for i,v in ipairs(self.queuedtweens) do
		if v.time <= self.beat and not v.run then
			v.func()
			v.run = true
		end
	end
	
	
	self.flux.update(deltaBeat)
	for i,v in ipairs(self.tweens) do
		if v.doremove then
			table.remove(self.tweens,i)
		end
	end
end

function ricewine:to(obj,length,kvtable)
	if length == 0 then
		for k,v in pairs(kvtable) do
			obj[k] = v
		end
	end
	local newtween = self.flux.to(obj,length,kvtable)
	table.insert(self.tweens,newtween)
	self.flux.update(0)
	return newtween
end

function ricewine:play(beat)

	self.startBeat = beat
	self.beat = beat

	table.sort(self.queuedtweens,function(k1, k2)
		if k1.time ~= k2.time then
			return k1.time < k2.time
		end
		k1.order = k1.order or 0
		k2.order = k2.order or 0
		return k1.order < k2.order
	end)

end

return ricewine