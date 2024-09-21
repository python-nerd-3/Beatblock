local em = {
  deep = deeper.init(),
  entities = {},
	paused = false
}


function em.new(fname,name)
  em.entities[name] = love.filesystem.load(fname)() -- this is a bad idea  
  print("made entity ".. name .." from " ..fname)
end

function em.init(en,kvtable)
  local succ, new = pcall(function() return em.entities[en]:new(kvtable) end)
  if not succ then
    print(new)
    error('tried to init entity named ' .. en ..', which did not exist')
  end

--  for k,v in pairs(kvtable) do
--    new[k] = v
--  end
--  new.name = en
  if (not new.skipUpdate) or (not new.skipRender) then
    table.insert(entities,new)
    return entities[#entities]
  else
    return new
  end

 
end


function em.update(dt)
  
  
  for i,v in ipairs(entities) do
    if (not v.skipUpdate) and (not v.isObjectInactive) then
      if not em.paused then
        em.deep.queue(v.upLayer, em.update2, v, dt)
      elseif v.runonpause then
        em.deep.queue(v.upLayer, em.update2, v, dt)
      end
    end
  end
  em.deep.execute() -- OH MY FUCKING GOD IM SUCH A DINGUS
end


function em.draw()
  
  for i, v in ipairs(entities) do
    if (not v.skipRender) and (not v.isObjectInactive) then

      em.deep.queue(v.layer, function() 
        if v.delete or v.skipRender then return end
        v:draw() 
      end)
      
    end
  end
  em.deep.execute()
	
	em.dodelete()
	
end

function em.dodelete()
	for i,v in ipairs(entities) do
    if v.delete then
      if v.onDelete then
        v:onDelete()
      end
      table.remove(entities, i)
    end
  end
end


function em.update2(v,dt)
  if v.skipUpdate or v.delete then return end
  v:update(dt)
end


return em