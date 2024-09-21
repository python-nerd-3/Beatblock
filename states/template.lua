local st = Gamestate:new('templatestate')

st:setInit(function(self)
  em.init('templateobj',{x=128,y=72})
end)


st:setUpdate(function(self,dt)
  
end)

st:setBgDraw(function(self)
  color('black')
  love.graphics.rectangle('fill',0,0,project.res.x,project.res.y)
end)
--entities are drawn here
st:setFgDraw(function(self)
  
  color('red')
  love.graphics.print(loc.get('helloworld'),10,10)
  
end)

return st