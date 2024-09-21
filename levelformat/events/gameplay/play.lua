local info = {
	event = 'play',
	name = 'Play song',
	storeInChart = false,
	allowInNoVFX = true,
	description = [[Parameters:
time: Beat to start playing song
file: Filename of song 
bpm: BPM of song
]]
}

--onLoad, onOffset, onBeat
local function onLoad(event)
	
	if string.sub(event.file,-4) == '.mp3' then
		cs:playbackError('.MP3 files for music are not supported due to sync issues. Please convert your file to an .ogg or a .wav file before using it.')
	end
	
	if math.floor(event.bpm*1000 + 0.5) == 1234 then
		cs:playbackError('You haven\'t changed the default BPM! Please find the BPM and offset of the song, and set it in the Play Song event correctly, otherwise your level won\'t sync properly.')
	end
	
	cs.level.bpm = event.bpm
	if cs.rateMod then
		cs.level.bpm = cs.level.bpm * cs.rateMod
	end
	
	cs.timingInfo.initial = {bpm = event.bpm, offsetSeconds = event.offset}
	if not pcall(function() cs.soundData = love.sound.newSoundData(cLevel..event.file) end) then
		cs:playbackError('Could not load song file "' .. cLevel..event.file .. '"')
		return
	end
	pq = pq .. "      loaded soundData"
end

local function onBeat(event)
	local volume = (savedata.options.audio.musicvolume/10)
	if event.volume then
		volume = volume * event.volume
	end
	cs.source = lovebpm.newTrack()
		:load(cs.soundData)
		:setTiming(cs.timingInfo)
		:setVolume(volume)
		:play()
		:on("end", function(f) print("song finished!!!!!!!!!!") cs.gm.songFinished = true end)
	cs.songOffset = event.time
	cs.source:setBeat(cs.cBeat - event.time)
	pq = pq .. "    ".. "now playing ".. event.file
	
	if cs.rateMod then
		cs.source:setPitch(cs.rateMod)
	end
	
end

local function editorDraw(event)
	local pos = cs:getPosition(event.angle,event.time)
	
	love.graphics.draw(sprites.editor.events.play,pos[1],pos[2],0,1,1,8,8)
end

local function editorProperties(event)
	Event.property(event,'string', 'file', 'Filename of song', {default = ''})
	Event.property(event,'decimal', 'bpm', 'BPM of song', {step = 1, default = 1.234})
	Event.property(event,'decimal', 'volume', 'Volume of song, 1 = 100% volume', {step = .1, default = 1})
	Event.property(event,'decimal', 'offset', 'Offset of the song, in seconds.', {optional = true, step = .001, default = 0, min = 0})
end

return info, onLoad, onOffset, onBeat, editorDraw, editorProperties