MenuMusicManager = class('MenuMusicManager',Entity)

function MenuMusicManager:initialize(params)
  
	self.skipRender = true
	self.skipUpdate = true
  self.layer = 0 -- lower layers draw first
  self.upLayer = 0 --lower upLayer updates first
  self.x = 0
  self.y = 0
  Entity.initialize(self,params)
	
	self.music = lovebpm.newTrack()
	self.onBeat = {}
	
	self.lastBeat = -1

end

function MenuMusicManager:addOnBeatHook(func)
	table.insert(self.onBeat,func)
end
function MenuMusicManager:clearOnBeatHooks()
	self.onBeat = {}
end

function MenuMusicManager:play()
	if savedata.options.audio.playMenuMusic then
		self.music
			:load('assets/music/menuloop.ogg')
			:setBPM(108)
			:setLooping(true)
			:play()
	end
end

function MenuMusicManager:stop()
	self.music:stop()
end

function MenuMusicManager:update(dt)
  prof.push("MenuMusicManager update")
	self.music:setVolume(savedata.options.audio.musicvolume/10)
	self.music:update()
	local beat = math.floor(self.music:getBeat())
	if beat ~= self.lastBeat then
		self.lastBeat = beat
		for i,v in ipairs(self.onBeat) do
			v(beat)
		end
	end
	
  prof.pop("MenuMusicManager update")
end

function MenuMusicManager:draw()
	
end

return MenuMusicManager