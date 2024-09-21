dpf = {}


function dpf.loadJson(f,w)
  print("dpf loading "..f)
  local cf = love.filesystem.read(f)
  if cf == nil then
		if not w then
			error('Could not load file ' .. f)
		end
		love.filesystem.createDirectory(helpers.rliid(f)) 
    print("trying to write a file cause it didnt exist")
    print(love.filesystem.write(f,json.encode(w)))
    cf = json.encode(w)
  end
  return json.decode(cf)
end

function dpf.saveJson(f,w)
	local newdir = helpers.rliid(f)
	if newdir ~= "" then
		love.filesystem.createDirectory(helpers.rliid(f)) 
	end
	love.filesystem.write(f,json.encode(w))
end


function dpf.patchLoveFilesystem()
	--returns true if a file is in savedata, not source code. If the file exists in neither, returns true. If the file exists in both, returns false.
	function love.filesystem.inSaveData(filename)
		local realdir = love.filesystem.getRealDirectory(filename)
		return realdir == nil or realdir == love.filesystem.getSaveDirectory()
	end
	
	--set whether or not saving in source code should be forced
	function love.filesystem.forceSaveInSource(doForce)
		love.filesystem.saveInSource = doForce
	end
	
	local oldWrite = love.filesystem.write
	local oldCreateDirectory = love.filesystem.createDirectory
	
	function love.filesystem.write(name, data, size)
		local saveInSource = love.filesystem.saveInSource or (not love.filesystem.inSaveData(name))
		saveInSource = saveInSource and (not love.filesystem.isFused()) --if fused, force to no
		if saveInSource then
			if helpers.rliid(name) ~= '' then
				love.filesystem.createDirectory(helpers.rliid(name), true)
			end
			local file = io.open(love.filesystem.getSource() ..'/'..name,'w')
			file:write(data)
			file:close()
		else
			return oldWrite(name, data, size)
		end
	end
	
	function love.filesystem.createDirectory(name, force)
		if love.filesystem.getInfo(name, 'directory') then
			return false
		end
		if force or (love.filesystem.saveInSource and (not love.filesystem.isFused())) then
			local handle = io.popen('md "' .. love.filesystem.getSource() ..'/'.. name ..'"')
			handle:close()
		else
			return oldCreateDirectory(name)
		end
	end
	

end

return dpf