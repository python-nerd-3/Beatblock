local st = Gamestate:new('EditorWarning')

st:setInit(function(self)
	self.caution = ez.newjson('assets/editor/warning/caution'):instance()
	shuv.resetPal()
	shuv.pal[2] = {r=255,g=216,b=0}
	te.play('assets/music/caution.ogg','stream','music')
end)


st:setUpdate(function(self,dt)
  self.caution:update(dt)
	if maininput:pressed("accept") then
		te.stop('music')
		
		savedata.seenEditorWarning = true
		sdfunc.save()
		
		local newLevel = self.newLevel
		cs = bs.load('Editor')
		cs.newLevel = newLevel
		cs:init()
		
	end
	if maininput:pressed("back") then
		te.stop('music')
		cs = bs.load(returnData.state)
		for k,v in pairs(returnData.vars) do
			cs[k] = v
		end
		cs:init()
	end
end)

st:setBgDraw(function(self)
	color()
	love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
	self.caution:draw()
	love.graphics.setFont(fonts.main)
	color(1)
	love.graphics.printf(loc.get('editorWarning'),10,220,(project.res.x-20)/2,'center',0,2,2)
end)
--entities are drawn here
st:setFgDraw(function(self)

end)

return st