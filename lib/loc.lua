local loc = {
  lang = "en",
  json=nil
}
function loc.load(j)
  loc.json = dpf.loadJson(j,{})
  print("localization file loaded")
end
function loc.setLang(l)
  loc.lang = l
  --print("set language")
end
function loc.get(s,ins)
  
  local outstr = loc.lang .. "."..s
  if loc.json[s] then
    if loc.json[s][loc.lang] then
      outstr = loc.json[s][loc.lang]
    end
  end
  
  if ins then
    for i,v in ipairs(ins) do
      outstr = string.gsub(outstr,'@@'..tostring(i)..'@@',v)
    end
  end
  return outstr
end

function loc.try(s)
	if string.sub(s,1,4) == 'loc@' and loc.json[string.sub(s,5)] then
		return loc.get(string.sub(s,5))
	else
		return s
	end
end
return loc