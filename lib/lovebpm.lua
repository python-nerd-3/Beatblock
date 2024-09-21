--- @class (exact) InitialTimingPoint
--- @field bpm number
--- @field offsetSeconds number

--- @class (exact) UncomputedTimingPoint
--- @field beat number
--- @field bpm number

--- @class (exact) UncomputedTimingData
--- @field initial InitialTimingPoint
--- @field timingPoints UncomputedTimingPoint[]

--- @class (exact) TimingPoint
--- @field time number
--- @field beat number
--- @field bpm number

--- @alias TimingData TimingPoint[]

--- @class (exact) Track
--- @field source any | nil
--- @field volume number
--- @field pitch number
--- @field looping boolean
--- @field listeners table<string, function[]>
--- @field lastBeat number | nil
--- @field lastUpdateTime number | nil
--- @field lastSourceTime number | nil
--- @field time number
--- @field totalTime number
--- @field dtMultiplier number
--- @field timing TimingData

local lovebpm = { _version = "0.0.0" }
local Track = {}
Track.__index = Track

function lovebpm.newTrack()
	local self = setmetatable({}, Track)
	self.source = nil
	self.volume = 1
	self.pitch = 1
	self.looping = false
	self.listeners = {}
	self.lastBeat = nil
	self.lastUpdateTime = nil
	self.lastSourceTime = 0
	self.time = 0
	self.totalTime = 0
	self.dtMultiplier = 1
	self.timing = {
		{
			time = 0,
			beat = 0,
			bpm = 120,
		},
	}

	return self
end

function Track:load(filename)
	-- Deinit old source
	self:stop()
	-- Init new source
	-- "static" mode is used here instead of "stream" as the time returned by
	-- :tell() seems to go out of sync after the first loop otherwise
	self.source = love.audio.newSource(filename, "static")
	self:setLooping(self.looping)
	self:setVolume(self.volume)
	self:setPitch(self.pitch)
	self.totalTime = self.source:getDuration("seconds")
	self:stop()
	return self
end

function Track:setVolume(volume)
	self.volume = volume or 1
	if self.source then
		self.source:setVolume(self.volume)
	end
	return self
end

function Track:setPitch(pitch)
	self.pitch = pitch or 1
	if self.source then
		self.source:setPitch(self.pitch)
	end
	return self
end

function Track:setLooping(loop)
	self.looping = loop
	if self.source then
		self.source:setLooping(self.looping)
	end
	return self
end

function Track:on(name, fn)
	self.listeners[name] = self.listeners[name] or {}
	table.insert(self.listeners[name], fn)
	return self
end

function Track:emit(name, ...)
	if self.listeners[name] then
		for i, fn in ipairs(self.listeners[name]) do
			fn(...)
		end
	end
	return self
end

function Track:play(restart)
	if not self.source then
		return self
	end
	if self.restart then
		self:stop()
	end
	self.source:play()
	return self
end

function Track:pause()
	if not self.source then
		return self
	end
	self.source:pause()
	return self
end

function Track:stop()
	self.lastBeat = nil
	self.time = 0
	self.lastUpdateTime = nil
	self.lastSourceTime = 0
	if self.source then
		self.source:stop()
	end
	return self
end

function Track:setTime(time)
	if not self.source then
		return
	end
	self.source:seek(time)
	self.time = time
	self.lastSourceTime = time
	self.lastBeat = math.floor(self:getBeat() - 1)
	return self
end

--- @param beat number
function Track:setBeat(beat)
	local timingPoint = self:findTimingPointByBeat(beat)
	if not timingPoint then
		error("uh oh ! something has gone very wrong !! are there no timing points???")
	end

	local period = 60 / timingPoint.bpm
	local time = timingPoint.time + (beat - timingPoint.beat) * period
	self:setTime(time)
end

--- returns the timing point that is closest to and earlier than the given time
--- @param time number
function Track:findTimingPointByTime(time)
	local timing = self.timing
	for i = 1, #timing do
		if timing[i].time > time then
			return self.timing[i - 1] or self.timing[1]
			--really really hope this doesn't mess with anything, in theory it shouldnt?? but if it does well whoops.
		end
	end

	return self.timing[#timing]
end

--- returns the timing point that is closest to and earlier than the given time
--- @param beat number
function Track:findTimingPointByBeat(beat)
	local timing = self.timing
	for i = 1, #timing do
		if timing[i].beat > beat then
			return self.timing[i - 1] or self.timing[1]
		end
	end

	return self.timing[#timing]
end


function Track:setBPM(bpm)
	self:setTiming({ initial = { bpm = bpm, offsetSeconds = 0 }, timingPoints = {} })
	return self
end

--- @param timing UncomputedTimingData
function Track:setTiming(timing)
	self.timing = {}

	local lastBPM = timing.initial.bpm
	local lastTime = timing.initial.offsetSeconds or 0
	local lastBeat = 0

	-- add the initial timing point
	table.insert(self.timing, {
		time = lastTime,
		beat = lastBeat,
		bpm = lastBPM,
	})

	if not timing.timingPoints or #timing.timingPoints == 0 then
		return self
	end

	-- calculate the time for each timing point
	for _, tp in ipairs(timing.timingPoints) do
		local time = lastTime + (tp.beat - lastBeat) / lastBPM * 60
		table.insert(self.timing, {
			time = time,
			beat = tp.beat,
			bpm = tp.bpm,
		})
		lastTime = time
		lastBeat = tp.beat
		lastBPM = tp.bpm
	end

	return self
end

function Track:getTotalTime()
	return self.totalTime
end

function Track:getTotalBeats()
	if not self.source then
		return 0
	end

	local totalTime = self:getTotalTime()
	local timingPoint = self.timing[#self.timing]
	local period = 60 / timingPoint.bpm
	return timingPoint.beat + (totalTime - timingPoint.time) / period
end

function Track:getTime()
	return self.time
end

function Track:getBeat()
	local time = self:getTime()
	local timingPoint = self:findTimingPointByTime(time)
	if not timingPoint then
		error("uh oh ! something has gone very wrong !! are there no timing points???")
	end
	local period = 60 / timingPoint.bpm
	return timingPoint.beat + (time - timingPoint.time) / period
end

function Track:update()
	if not self.source then
		return self
	end

	-- Get delta time: getTime() is used for time-keeping as the value returned by
	-- :tell() is updated at a potentially lower rate than the framerate
	local t = love.timer.getTime()
	local dt = self.lastUpdateTime and (t - self.lastUpdateTime) or 0
	self.lastUpdateTime = t

	-- Set new time
	local time
	if self.source:isPlaying() then
		time = self.time + dt * self.dtMultiplier * self.pitch
	else
		time = self.time
	end

	local sourceTime = self.source:tell("seconds")

	-- If the value returned by the :tell() function has updated we check to see
	-- if we are in sync within an allowed threshold -- if we're out of sync we
	-- adjust the dtMultiplier to resync gradually
	if sourceTime ~= self.lastSourceTime then
		local diff = time - sourceTime
		-- Check if the difference is beyond the threshold -- If the difference is
		-- too great we assume the track has looped and treat it as being within the
		-- threshold
		if math.abs(diff) > 0.01 and math.abs(diff) < self.totalTime / 2 then
			self.dtMultiplier = math.max(0, 1 - diff * 2)
		else
			self.dtMultiplier = 1
		end
		self.lastSourceTime = sourceTime
	end

	-- Assure time is within proper bounds in case the offset or added
	-- frame-delta-time made it overshoot
	time = time % self.totalTime

	-- Calculate deltatime and emit update event; set time
	if self.lastBeat then
		local t = time
		if t < self.time then
			t = t + self.totalTime
		end
		self:emit("update", t - self.time)
	else
		self:emit("update", 0)
	end
	self.time = time

	-- Current beat doesn't match last beat?
	local beat = math.floor(self:getBeat())
	local last = self.lastBeat
	if beat ~= last then
		-- Last beat is set here as one of the event handlers can potentially set it
		-- by calling :setTime() or :setBeat()
		self.lastBeat = beat
		-- Assure that the `beat` event is done once for each beat, even in cases
		-- where more than one beat has passed since the last update, or the song
		-- has looped
		local total = self:getTotalBeats()
		local b = beat
		local x = 0
		if last then
			x = last + 1
			-- If the last beat is greater than the current beat then the song has
			-- reached the end: if we're looping then set the current beat to after
			-- the tracks's end so incrementing towards it still works.
			if x > b then
				if self.looping then
					self:emit("loop")
					b = b + total
				else
					self:emit("end")
					print("end")
					self:stop()
				end
			end
		end
	end

	return self
end

return lovebpm
