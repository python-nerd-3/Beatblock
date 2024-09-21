local st = Gamestate:new('SongSelectOld')


st:setInit(function(self)
  self.fg = sprites.songselect.fg
	
  self.cDir = "levels/"
  self.p = em.init('Player',{x=350,y=120})
  self.levels = self:refresh()

  self.levelCount = #self.levels --Get the # of levels in the songlist
  self.cRank = "none"
  self.selection = 1
  self.move = false
  self.dispY = -60
end)

function st:refresh()
  local cList = love.filesystem.getDirectoryItems(self.cDir)
  local levels = {}
  print("cList")
  for i,v in ipairs(cList) do
    if love.filesystem.getInfo(self.cDir .. v .. "/level.json") then
      local cLevelMetadata = LevelManager:loadMetadata(self.cDir..v..'/')
      table.insert(levels,{isLevel = true,songName=cLevelMetadata.metadata.songName,artist=cLevelMetadata.metadata.artist,filename=self.cDir .. v .. "/"})
    elseif love.filesystem.getInfo(self.cDir .. v .. "/").type == "directory" then
      
      table.insert(levels,{isLevel = false,name = v,filename=self.cDir .. v .. "/"})
    end
  end
  if self.cDir ~= "levels/" then
    local fname = self.cDir
    table.insert(levels,{isLevel=false,name=loc.get("back"),filename=helpers.rliid(fname)})
  end
  self.selection = 1
  self.playedLevelsJson = dpf.loadJson("savedata/playedlevels.json",{})
  return levels
  
end




function st:leave()
  self.p.delete = true
  self.p=nil
end


function st.resume()

end
--[[
function st.mousepressed(x,y,b,t,p)
  if ismobile then
    local newSelection = st.selection
    if (love.mouse.getY()/shuv.scale) < 240/3 then
      newSelection = st.selection - 1
      st.move = true
    elseif (love.mouse.getY()/shuv.scale) > 240/3*2 then
      newSelection = st.selection + 1
      st.move = true
    else
      if st.levels[st.selection].isLevel then
        cLevel = st.levels[st.selection].filename
        helpers.swap(states.game)
      else
        st.cDir = st.levels[st.selection].filename
        st.levels = st.refresh()

        st.levelCount = #st.levels --Get the # of levels in the songlist

        st.selection = 1
        st.move = true
        st.dispY = -60
      end
    end
    if st.move then
      if newSelection >= 1 and newSelection <= st.levelCount then --Only move the cursor if it's within the bounds of the level list
        st.selection = newSelection
        te.play(sounds.click,"static")
        st.ease = flux.to(st,30,{dispY=st.selection*-60}):ease("outExpo")
      end
      if st.levels[st.selection].isLevel then
        local cLevelMetadata = dpf.loadJson(st.levels[st.selection].filename .. "level.json")
        if st.playedLevelsJson[cLevelMetadata.metadata.songName.."_"..cLevelMetadata.metadata.charter] then
          local cPct = st.playedLevelsJson[cLevelMetadata.metadata.songName.."_"..cLevelMetadata.metadata.charter].pctGrade
          local sn,ch = helpers.gradeCalc(cPct)
          st.cRank = sn .. ch
        else
          st.cRank = "none"
        end
      else
        st.cRank = "none"
      end
      st.move = false
    end
  end
end
]]

st:setUpdate(function(self,dt)
  pq = ""
  if not paused then
    local newSelection = self.selection
    if maininput:pressed("menu_up") then
      newSelection = self.selection - 1
      self.move = true
    end
    if maininput:pressed("menu_down") then
      newSelection = self.selection + 1
      self.move = true
    end
    if maininput:pressed("accept") then
      if self.levels[self.selection].isLevel then
        cLevel = self.levels[self.selection].filename
				self:leave()
        cs = bs.load('Game')
				cs:init()
      else
        self.cDir = self.levels[self.selection].filename
        self.levels = self:refresh()
        
        self.levelCount = #self.levels --Get the # of levels in the songlist
        if self.ease then
          self.ease:stop()
        end
        self.selection = 1
        self.move = true
        te.play(sounds.click,"static")
        self.ease = flux.to(self,30,{dispY=self.selection*-60}):ease("outExpo")
        --self.dispY = -60

        newSelection = 1
      end
    end
    if maininput:pressed("e") then
			if not maininput:down('ctrl') then
				if self.levels[self.selection].isLevel then
					cLevel = self.levels[self.selection].filename
					self:leave()
					cs = bs.load('Editor')
					cs:init()
				end
			else
				self:leave()
				cs = bs.load('Editor')
				cLevel = self.cDir
				cs.newLevel = true
				cs:init()
			end
    end
    if self.move then
      if newSelection >= 1 and newSelection <= self.levelCount then --Only move the cursor if it's within the bounds of the level list
        self.selection = newSelection
        te.play(sounds.click,"static")
        self.ease = flux.to(self,30,{dispY=self.selection*-60}):ease("outExpo")
      end
      if self.levels[self.selection].isLevel then
        local cLevelMetadata = LevelManager:loadMetadata(self.levels[self.selection].filename) --TODO: probably should cache levels as they are passed over to avoid loading it twice?
        if self.playedLevelsJson[cLevelMetadata.metadata.songName.."_"..cLevelMetadata.metadata.charter] then
          local cPct = self.playedLevelsJson[cLevelMetadata.metadata.songName.."_"..cLevelMetadata.metadata.charter].pctGrade --REWRITE: will need to either be left, or changed in savedata management
          local sn,ch = GameManager:gradeCalc(cPct)
          self.cRank = sn .. ch
        else
          self.cRank = "none"
        end
      else
        self.cRank = "none"
      end
      self.move = false
    end
  end
end)


st:setBgDraw(function(self)
  love.graphics.setFont(fonts.digitalDisco)
  --push:start()

  color('white')
  love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
	
  love.graphics.draw(self.fg,2,-2)
  color('black')
	
  for i,v in ipairs(self.levels) do
      if v.isLevel then
        love.graphics.print(v.songName,10,70+i*60+self.dispY,0,2,2)
        love.graphics.print(v.artist,10,100+i*60+self.dispY)
      else
        love.graphics.print(v.name,10,76+i*60+self.dispY,0,2,2)
        --love.graphics.print(v.artist,10,100+i*60+self.dispY)
      end
  end
end)

--em.draw()
st:setFgDraw(function(self)
	color()
  if self.cRank ~= "none" then
    love.graphics.draw(sprites.songselect.grades[self.cRank],320,20)
  end
  if pq ~= "" then
    --print(helpers.round(self.cBeat*6,true)/6 .. pq)
    
  end

  shuv.finish()
end)


return st